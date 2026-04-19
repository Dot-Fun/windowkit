import Carbon.HIToolbox
import Foundation
import PreferencesStore
import WindowEngine

/// Registers global hotkeys via Carbon `RegisterEventHotKey` and invokes
/// `onAction` when one fires. Re-registering replaces all prior registrations.
///
/// Main-actor isolated: Carbon's event handler runs on the main run loop.
@MainActor
public final class HotkeyManager {
    public var onAction: ((WindowAction) -> Void)?

    private struct Registration {
        let hotKeyRef: EventHotKeyRef
        let action: WindowAction
    }

    private var registrations: [UInt32: Registration] = [:]
    private var idToAction: [UInt32: WindowAction] = [:]
    private var eventHandlerRef: EventHandlerRef?
    private var nextID: UInt32 = 1
    private static let signature: OSType = 0x574B4954 // 'WKIT'

    /// Maps our manager pointer -> closure used by the C callback. Accessed
    /// only from the Carbon event handler (main thread) and from main-actor
    /// methods, so we mark the storage nonisolated(unsafe) rather than
    /// fighting the type system.
    nonisolated(unsafe) private static var dispatchers: [ObjectIdentifier: (UInt32) -> Void] = [:]

    public init() {
        installEventHandler()
    }

    deinit {
        // Deinit runs off the main actor; unregister Carbon refs directly
        // (these APIs are thread-safe enough for teardown) and drop our
        // dispatcher entry.
        for (_, reg) in registrations {
            UnregisterEventHotKey(reg.hotKeyRef)
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
    }

    public func clear() {
        for (_, reg) in registrations {
            UnregisterEventHotKey(reg.hotKeyRef)
        }
        registrations.removeAll()
        idToAction.removeAll()
    }

    // MARK: - Internals

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
                guard let self, let action = self.idToAction[id] else { return }
                self.onAction?(action)
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
