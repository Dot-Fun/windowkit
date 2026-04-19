import AppKit
import ApplicationServices
import Combine
import Foundation

public enum AccessibilityTrust {
    public static func isTrusted(prompt: Bool = false) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public static func openSystemSettings() {
        let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility")!
        NSWorkspace.shared.open(url)
    }

    public static func trustPublisher(interval: TimeInterval = 1.0) -> AnyPublisher<Bool, Never> {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .map { _ in isTrusted(prompt: false) }
            .prepend(isTrusted(prompt: false))
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
