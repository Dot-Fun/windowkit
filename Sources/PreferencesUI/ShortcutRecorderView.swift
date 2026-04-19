import AppKit
import Carbon.HIToolbox
import PreferencesStore
import SwiftUI

public struct ShortcutRecorderView: View {
    @Binding public var shortcut: Shortcut?
    @State private var isRecording: Bool = false

    public init(shortcut: Binding<Shortcut?>) {
        self._shortcut = shortcut
    }

    public var body: some View {
        HStack(spacing: 6) {
            ShortcutRecorderRepresentable(
                shortcut: $shortcut,
                isRecording: $isRecording
            )
            .frame(minWidth: 160, minHeight: 22)

            if shortcut != nil {
                Button {
                    shortcut = nil
                    isRecording = false
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)
                .help("Clear shortcut")
            }
        }
    }
}

private struct ShortcutRecorderRepresentable: NSViewRepresentable {
    @Binding var shortcut: Shortcut?
    @Binding var isRecording: Bool

    func makeNSView(context: Context) -> ShortcutRecorderNSView {
        let v = ShortcutRecorderNSView()
        v.onCapture = { sc in
            shortcut = sc
            isRecording = false
        }
        v.onRecordingChange = { rec in
            if isRecording != rec { isRecording = rec }
        }
        return v
    }

    func updateNSView(_ nsView: ShortcutRecorderNSView, context: Context) {
        nsView.shortcut = shortcut
        nsView.isRecording = isRecording
        nsView.refreshLabel()
    }
}

final class ShortcutRecorderNSView: NSView {
    var shortcut: Shortcut?
    var isRecording: Bool = false {
        didSet { needsDisplay = true }
    }
    var onCapture: ((Shortcut?) -> Void)?
    var onRecordingChange: ((Bool) -> Void)?

    private let label = NSTextField(labelWithString: "")

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer?.cornerRadius = 5
        layer?.borderWidth = 1
        label.translatesAutoresizingMaskIntoConstraints = false
        label.alignment = .center
        label.font = .systemFont(ofSize: NSFont.systemFontSize)
        label.textColor = .labelColor
        addSubview(label)
        NSLayoutConstraint.activate([
            label.centerXAnchor.constraint(equalTo: centerXAnchor),
            label.centerYAnchor.constraint(equalTo: centerYAnchor),
            label.leadingAnchor.constraint(greaterThanOrEqualTo: leadingAnchor, constant: 6),
            label.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor, constant: -6),
        ])
        refreshLabel()
        updateBorder()
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) not implemented") }

    override var acceptsFirstResponder: Bool { true }
    override func becomeFirstResponder() -> Bool {
        let ok = super.becomeFirstResponder()
        if ok {
            isRecording = true
            onRecordingChange?(true)
            refreshLabel()
            updateBorder()
        }
        return ok
    }

    override func resignFirstResponder() -> Bool {
        isRecording = false
        onRecordingChange?(false)
        refreshLabel()
        updateBorder()
        return super.resignFirstResponder()
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }

    override func keyDown(with event: NSEvent) {
        let mods = carbonModifiers(from: event.modifierFlags)
        let keyCode = UInt32(event.keyCode)

        if keyCode == UInt32(kVK_Escape) && mods == 0 {
            window?.makeFirstResponder(nil)
            return
        }
        if keyCode == UInt32(kVK_Delete) && mods == 0 {
            shortcut = nil
            onCapture?(nil)
            window?.makeFirstResponder(nil)
            return
        }
        guard mods != 0 else {
            NSSound.beep()
            return
        }
        let captured = Shortcut(keyCode: keyCode, modifiers: mods)
        shortcut = captured
        onCapture?(captured)
        window?.makeFirstResponder(nil)
    }

    override func performKeyEquivalent(with event: NSEvent) -> Bool {
        guard isRecording, window?.firstResponder === self else {
            return super.performKeyEquivalent(with: event)
        }
        keyDown(with: event)
        return true
    }

    func refreshLabel() {
        if isRecording {
            label.stringValue = "Type shortcut…"
            label.textColor = .secondaryLabelColor
        } else if let sc = shortcut {
            label.stringValue = ShortcutFormatter.string(from: sc)
            label.textColor = .labelColor
        } else {
            label.stringValue = "Click to record"
            label.textColor = .tertiaryLabelColor
        }
    }

    private func updateBorder() {
        layer?.borderColor = (isRecording ? NSColor.controlAccentColor : NSColor.separatorColor).cgColor
        layer?.backgroundColor = (isRecording ? NSColor.controlAccentColor.withAlphaComponent(0.08) : NSColor.controlBackgroundColor).cgColor
    }

    private func carbonModifiers(from flags: NSEvent.ModifierFlags) -> UInt32 {
        var m: UInt32 = 0
        if flags.contains(.command)  { m |= UInt32(cmdKey) }
        if flags.contains(.option)   { m |= UInt32(optionKey) }
        if flags.contains(.control)  { m |= UInt32(controlKey) }
        if flags.contains(.shift)    { m |= UInt32(shiftKey) }
        return m
    }
}

public enum ShortcutFormatter {
    public static func string(from shortcut: Shortcut) -> String {
        var parts = ""
        if shortcut.modifiers & UInt32(controlKey) != 0 { parts += "⌃" }
        if shortcut.modifiers & UInt32(optionKey)  != 0 { parts += "⌥" }
        if shortcut.modifiers & UInt32(shiftKey)   != 0 { parts += "⇧" }
        if shortcut.modifiers & UInt32(cmdKey)     != 0 { parts += "⌘" }
        parts += keyName(for: shortcut.keyCode)
        return parts
    }

    private static func keyName(for keyCode: UInt32) -> String {
        switch Int(keyCode) {
        case kVK_Return:        return "↩"
        case kVK_Tab:           return "⇥"
        case kVK_Space:         return "Space"
        case kVK_Delete:        return "⌫"
        case kVK_ForwardDelete: return "⌦"
        case kVK_Escape:        return "⎋"
        case kVK_LeftArrow:     return "←"
        case kVK_RightArrow:    return "→"
        case kVK_UpArrow:       return "↑"
        case kVK_DownArrow:     return "↓"
        case kVK_ANSI_Comma:    return ","
        case kVK_ANSI_Period:   return "."
        case kVK_ANSI_Slash:    return "/"
        case kVK_ANSI_Equal:    return "="
        case kVK_ANSI_Minus:    return "-"
        case kVK_ANSI_Semicolon:return ";"
        case kVK_ANSI_Quote:    return "'"
        case kVK_ANSI_LeftBracket:  return "["
        case kVK_ANSI_RightBracket: return "]"
        case kVK_ANSI_Backslash:    return "\\"
        case kVK_ANSI_Grave:    return "`"
        case kVK_F1:  return "F1"
        case kVK_F2:  return "F2"
        case kVK_F3:  return "F3"
        case kVK_F4:  return "F4"
        case kVK_F5:  return "F5"
        case kVK_F6:  return "F6"
        case kVK_F7:  return "F7"
        case kVK_F8:  return "F8"
        case kVK_F9:  return "F9"
        case kVK_F10: return "F10"
        case kVK_F11: return "F11"
        case kVK_F12: return "F12"
        default:
            if let s = ansiCharacter(for: keyCode) { return s.uppercased() }
            return "Key \(keyCode)"
        }
    }

    private static func ansiCharacter(for keyCode: UInt32) -> String? {
        let map: [Int: String] = [
            kVK_ANSI_A: "a", kVK_ANSI_B: "b", kVK_ANSI_C: "c", kVK_ANSI_D: "d",
            kVK_ANSI_E: "e", kVK_ANSI_F: "f", kVK_ANSI_G: "g", kVK_ANSI_H: "h",
            kVK_ANSI_I: "i", kVK_ANSI_J: "j", kVK_ANSI_K: "k", kVK_ANSI_L: "l",
            kVK_ANSI_M: "m", kVK_ANSI_N: "n", kVK_ANSI_O: "o", kVK_ANSI_P: "p",
            kVK_ANSI_Q: "q", kVK_ANSI_R: "r", kVK_ANSI_S: "s", kVK_ANSI_T: "t",
            kVK_ANSI_U: "u", kVK_ANSI_V: "v", kVK_ANSI_W: "w", kVK_ANSI_X: "x",
            kVK_ANSI_Y: "y", kVK_ANSI_Z: "z",
            kVK_ANSI_0: "0", kVK_ANSI_1: "1", kVK_ANSI_2: "2", kVK_ANSI_3: "3",
            kVK_ANSI_4: "4", kVK_ANSI_5: "5", kVK_ANSI_6: "6", kVK_ANSI_7: "7",
            kVK_ANSI_8: "8", kVK_ANSI_9: "9",
        ]
        return map[Int(keyCode)]
    }
}
