import AppKit
import ApplicationServices
import Combine
import Foundation

public enum TrustState: Equatable {
    case functional
    case stale
    case denied
}

public enum AccessibilityTrust {
    public static func isTrusted(prompt: Bool = false) -> Bool {
        let key = kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String
        let options: CFDictionary = [key: prompt] as CFDictionary
        return AXIsProcessTrustedWithOptions(options)
    }

    public static func currentState() -> TrustState {
        if !isTrusted(prompt: false) { return .denied }
        return TrustCanary.isFunctional() ? .functional : .stale
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

    public static func statePublisher(interval: TimeInterval = 2.0) -> AnyPublisher<TrustState, Never> {
        Timer.publish(every: interval, on: .main, in: .common)
            .autoconnect()
            .map { _ in currentState() }
            .prepend(currentState())
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
}
