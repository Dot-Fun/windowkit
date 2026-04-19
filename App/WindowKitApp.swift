import AppKit
import Combine
import HotkeyManager
import PermissionsCoordinator
import PreferencesStore
import PreferencesUI
import SwiftUI
import UndoStack
import WindowEngine

@main
struct WindowKitApp: App {
    @NSApplicationDelegateAdaptor(WindowKitAppDelegate.self) private var appDelegate

    var body: some Scene {
        MenuBarExtra("WindowKit", systemImage: "rectangle.3.group") {
            Text("WindowKit")
                .disabled(true)
            Divider()
            Button("Preferences…") {
                appDelegate.openPreferences()
            }
            .keyboardShortcut(",", modifiers: .command)
            Button("About WindowKit") {
                NSApp.activate(ignoringOtherApps: true)
                NSApp.orderFrontStandardAboutPanel(nil)
            }
            Divider()
            Button("Quit WindowKit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        }
        .menuBarExtraStyle(.menu)
    }
}

@MainActor
final class WindowKitAppDelegate: NSObject, NSApplicationDelegate {
    private let store = PreferencesStore()
    private let hotkeys = HotkeyManager()
    private let undo = UndoStack(limit: 20)
    private lazy var runner = ActionRunner(undoStack: undo)

    private var preferencesWindow: NSWindow?
    private var onboardingWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var hotkeysArmed = false

    func applicationDidFinishLaunching(_ notification: Notification) {
        hotkeys.onAction = { [weak self] action, count in
            self?.runner.perform(action, tapCount: count)
        }
        hotkeys.tapWindowSeconds = { [weak store] in
            Double(store?.tapWindowMs ?? 400) / 1000.0
        }

        store.$bindings
            .dropFirst()
            .sink { [weak self] bindings in
                guard let self, self.hotkeysArmed else { return }
                self.hotkeys.apply(bindings: bindings)
            }
            .store(in: &cancellables)

        AccessibilityTrust.trustPublisher(interval: 1.0)
            .receive(on: RunLoop.main)
            .sink { [weak self] trusted in
                guard let self else { return }
                if trusted {
                    self.armHotkeys()
                    self.dismissOnboarding()
                } else {
                    self.disarmHotkeys()
                    self.showOnboarding()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Hotkeys

    private func armHotkeys() {
        hotkeys.apply(bindings: store.bindings)
        hotkeysArmed = true
    }

    private func disarmHotkeys() {
        hotkeys.clear()
        hotkeysArmed = false
    }

    // MARK: - Windows

    func openPreferences() {
        if preferencesWindow == nil {
            let hosting = NSHostingController(rootView: PreferencesWindow(store: store))
            let window = NSWindow(contentViewController: hosting)
            window.title = "WindowKit Preferences"
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 600, height: 560))
            window.isReleasedWhenClosed = false
            window.center()
            preferencesWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        preferencesWindow?.makeKeyAndOrderFront(nil)
    }

    private func showOnboarding() {
        guard onboardingWindow == nil else {
            onboardingWindow?.makeKeyAndOrderFront(nil)
            return
        }
        let view = OnboardingView { [weak self] in
            self?.dismissOnboarding()
        }
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Welcome to WindowKit"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 480, height: 360))
        window.center()
        onboardingWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func dismissOnboarding() {
        onboardingWindow?.close()
        onboardingWindow = nil
    }
}
