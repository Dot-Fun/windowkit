import AppKit
import CoreGraphics
import Foundation

/// One window's identity + frame at save time. `frame` is in AX coordinates
/// (global top-left origin), the same space `AXWindow.frame()/setFrame` use,
/// so a restore is a straight write with no conversion.
public struct WindowRecord: Codable, Equatable, Sendable {
    public var bundleID: String
    public var appName: String
    public var title: String
    public var frame: CGRect

    public init(bundleID: String, appName: String, title: String, frame: CGRect) {
        self.bundleID = bundleID
        self.appName = appName
        self.title = title
        self.frame = frame
    }
}

/// Fingerprint of the attached display arrangement: the set of screen frames
/// in global (NSScreen) coordinates. A profile only offers restore when the
/// live arrangement matches, because saved frames are meaningless on a
/// different monitor setup.
public struct DisplaySignature: Codable, Equatable, Sendable {
    /// Screen frames, kept sorted so comparison is order-insensitive.
    public var screens: [CGRect]

    public init(screens: [CGRect]) {
        self.screens = Self.sorted(screens)
    }

    public static func current() -> DisplaySignature {
        DisplaySignature(screens: NSScreen.screens.map(\.frame))
    }

    public func matches(_ other: DisplaySignature) -> Bool {
        screens == other.screens
    }

    /// e.g. "2 displays — 3840×2160, 1440×2560"
    public var summary: String {
        let count = screens.count
        let sizes = screens
            .map { "\(Int($0.width))×\(Int($0.height))" }
            .joined(separator: ", ")
        return "\(count) display\(count == 1 ? "" : "s") — \(sizes)"
    }

    private static func sorted(_ frames: [CGRect]) -> [CGRect] {
        frames.sorted {
            ($0.origin.x, $0.origin.y, $0.width, $0.height)
                < ($1.origin.x, $1.origin.y, $1.width, $1.height)
        }
    }
}

/// A named snapshot of every visible window (all displays, the currently
/// active Space on each). macOS offers no public API to reach windows on
/// hidden Spaces, so one profile per Space — switch to a Space, then save or
/// restore — is the intended workflow.
public struct LayoutProfile: Codable, Equatable, Identifiable, Sendable {
    public var id: UUID
    public var name: String
    public var signature: DisplaySignature
    public var windows: [WindowRecord]
    /// When true, this profile is restored automatically after the display
    /// arrangement it was saved on reconnects (sleep/wake, cable re-plug).
    public var autoRestore: Bool
    public var savedAt: Date

    public init(
        id: UUID = UUID(),
        name: String,
        signature: DisplaySignature,
        windows: [WindowRecord],
        autoRestore: Bool = false,
        savedAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.signature = signature
        self.windows = windows
        self.autoRestore = autoRestore
        self.savedAt = savedAt
    }
}
