import Carbon.HIToolbox
import Foundation
import PreferencesStore
import WindowEngine

/// Registers global hotkeys via Carbon `RegisterEventHotKey` and invokes
/// `onAction` when one fires. Re-registering replaces all prior registrations.
///
/// Also drives the numpad "sequence" language: the numeric keypad keys 1–9
/// can be registered under a shared modifier (`armNumpadSequence`); each press
/// fires `onSequenceDigit` so a higher layer can accumulate a region sequence.
///
/// Main-actor isolated: Carbon's event handler runs on the main run loop.
@MainActor
public final class HotkeyManager {
    public var onAction: ((WindowAction, Int) -> Void)?
    /// Fires with a numpad digit (1–9) when a registered numpad sequence key
    /// is pressed. Accumulation and commit are owned by the caller.
    public var onSequenceDigit: ((Int) -> Void)?
    public var tapWindowSeconds: () -> TimeInterval = { 0.7 }

    private struct Registration {
        let hotKeyRef: EventHotKeyRef
        let action: WindowAction
    }

    private var registrations: [UInt32: Registration] = [:]
    private var idToAction: [UInt32: WindowAction] = [:]

    // Numpad sequence keys are tracked separately so a binding change (which
    // re-`apply`s) never drops them.
    private var numpadRegistrations: [UInt32: EventHotKeyRef] = [:]
    private var idToDigit: [UInt32: Int] = [:]
    private var numpadModifiers: UInt32?
    private var sequenceLayout: SequenceKeyLayout = .numpad

    private var eventHandlerRef: EventHandlerRef?
    private var nextID: UInt32 = 1
    private let tapDetector: TapDetector
    private static let signature: OSType = 0x574B4954 // 'WKIT'

    /// Maps our manager pointer -> closure used by the C callback. Accessed
    /// only from the Carbon event handler (main thread) and from main-actor
    /// methods, so we mark the storage nonisolated(unsafe) rather than
    /// fighting the type system.
    nonisolated(unsafe) private static var dispatchers: [ObjectIdentifier: (UInt32) -> Void] = [:]

    public init(tapDetector: TapDetector? = nil) {
        self.tapDetector = tapDetector ?? TapDetector()
        installEventHandler()
    }

    deinit {
        // Deinit runs off the main actor; unregister Carbon refs directly
        // (these APIs are thread-safe enough for teardown) and drop our
        // dispatcher entry.
        for (_, reg) in registrations {
            UnregisterEventHotKey(reg.hotKeyRef)
        }
        for (_, ref) in numpadRegistrations {
            UnregisterEventHotKey(ref)
        }
        if let h = eventHandlerRef {
            RemoveEventHandler(h)
        }
        HotkeyManager.dispatchers.removeValue(forKey: ObjectIdentifier(self))
    }

    // MARK: - Public API

    public func apply(bindings: [WindowAction: Shortcut]) {
        clear()
        // Dedup: if two actions share (keyCode, modifiers), keep the first seen
        // (iteration order on a dictionary is unstable — sort for determinism).
        var seen: Set<UInt64> = []
        for (action, shortcut) in bindings.sorted(by: { $0.key.rawValue < $1.key.rawValue }) {
            guard shortcut.modifiers != 0 else { continue }
            let fingerprint = (UInt64(shortcut.keyCode) << 32) | UInt64(shortcut.modifiers)
            if !seen.insert(fingerprint).inserted { continue }
            registerOne(action: action, shortcut: shortcut)
        }
        // `clear()` dropped the numpad keys too; re-arm them so the sequence
        // language survives binding changes.
        registerNumpadKeys()
    }

    /// Enable the sequence language under `modifiers` (e.g. ⌃⌥⌘), driven by
    /// `layout`'s key set. Registration happens on the next `apply(bindings:)`
    /// (which always re-registers the sequence keys), so callers should pair
    /// this with `apply`. Keeping registration in one place avoids
    /// double-registering the keys.
    public func armNumpadSequence(modifiers: UInt32, layout: SequenceKeyLayout = .numpad) {
        numpadModifiers = modifiers
        sequenceLayout = layout
    }

    public func clear() {
        for (_, reg) in registrations {
            UnregisterEventHotKey(reg.hotKeyRef)
        }
        registrations.removeAll()
        idToAction.removeAll()
        clearNumpadKeys()
    }

    // MARK: - Internals

    private func clearNumpadKeys() {
        for (_, ref) in numpadRegistrations {
            UnregisterEventHotKey(ref)
        }
        numpadRegistrations.removeAll()
        idToDigit.removeAll()
    }

    private func registerNumpadKeys() {
        guard let mods = numpadModifiers else { return }
        clearNumpadKeys()
        // A 3×3 map of the screen (top row 7/8/9), on whichever key set the
        // current layout uses — numpad on a full keyboard, U/I/O on a laptop.
        for entry in sequenceLayout.keys {
            let id = nextID
            nextID += 1
            let hkID = EventHotKeyID(signature: HotkeyManager.signature, id: id)
            var ref: EventHotKeyRef?
            let status = RegisterEventHotKey(
                UInt32(entry.keyCode), mods, hkID, GetApplicationEventTarget(), 0, &ref
            )
            guard status == noErr, let ref else { continue }
            numpadRegistrations[id] = ref
            idToDigit[id] = entry.digit
        }
    }

    private func registerOne(action: WindowAction, shortcut: Shortcut) {
        let id = nextID
        nextID += 1

        let hkID = EventHotKeyID(signature: HotkeyManager.signature, id: id)
        var ref: EventHotKeyRef?
        let status = RegisterEventHotKey(
            shortcut.keyCode,
            shortcut.modifiers,
            hkID,
            GetApplicationEventTarget(),
            0,
            &ref
        )
        guard status == noErr, let ref else { return }
        registrations[id] = Registration(hotKeyRef: ref, action: action)
        idToAction[id] = action
    }

    private func installEventHandler() {
        HotkeyManager.dispatchers[ObjectIdentifier(self)] = { [weak self] id in
            // Carbon fires on the main thread; hop onto the main actor to
            // touch MainActor-isolated state safely.
            MainActor.assumeIsolated {
                guard let self else { return }
                if let action = self.idToAction[id] {
                    let count = self.tapDetector.register(action, window: self.tapWindowSeconds())
                    self.onAction?(action, count)
                } else if let digit = self.idToDigit[id] {
                    self.onSequenceDigit?(digit)
                }
            }
        }

        var spec = EventTypeSpec(
            eventClass: OSType(kEventClassKeyboard),
            eventKind: UInt32(kEventHotKeyPressed)
        )
        let userData = Unmanaged.passUnretained(self).toOpaque()
        InstallEventHandler(
            GetApplicationEventTarget(),
            HotkeyManager.eventHandlerCallback,
            1,
            &spec,
            userData,
            &eventHandlerRef
        )
    }

    private static let eventHandlerCallback: EventHandlerUPP = { _, eventRef, userData in
        guard let eventRef, let userData else { return OSStatus(eventNotHandledErr) }
        var hkID = EventHotKeyID()
        let status = GetEventParameter(
            eventRef,
            EventParamName(kEventParamDirectObject),
            EventParamType(typeEventHotKeyID),
            nil,
            MemoryLayout<EventHotKeyID>.size,
            nil,
            &hkID
        )
        guard status == noErr else { return status }

        let manager = Unmanaged<HotkeyManager>.fromOpaque(userData).takeUnretainedValue()
        if let dispatch = HotkeyManager.dispatchers[ObjectIdentifier(manager)] {
            dispatch(hkID.id)
        }
        return noErr
    }
}
