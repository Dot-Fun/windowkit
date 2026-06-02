import AppKit
import Combine
import HotkeyManager
import PermissionsCoordinator
import PreferencesStore
import PreferencesUI
import ServiceManagement
import SwiftUI
import UndoStack
import UpdateChecker
import WindowEngine

/// dotfun brand orange, sampled from the logo wordmark.
let dotfunOrange = Color(red: 0.97, green: 0.32, blue: 0.12)

@main
struct WindowKitApp: App {
    @NSApplicationDelegateAdaptor(WindowKitAppDelegate.self) private var appDelegate
    @State private var launchAtLogin: Bool = LaunchAtLogin.isEnabled
    @StateObject private var updateChecker: UpdateChecker = {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "0.0.0"
        return UpdateChecker(currentVersion: version, owner: "Dot-Fun", repo: "windowkit")
    }()

    var body: some Scene {
        MenuBarExtra {
            Text("WindowKit")
                .disabled(true)
            if let update = updateChecker.availableUpdate {
                Divider()
                Button("Update available — \(update.tagName) →") {
                    NSWorkspace.shared.open(update.htmlURL)
                }
            }
            Divider()
            Button("Preferences…") {
                appDelegate.openPreferences()
            }
            .keyboardShortcut(",", modifiers: .command)
            Button("About WindowKit") {
                appDelegate.openAbout(updateChecker: updateChecker)
            }
            Divider()
            Toggle("Launch at Login", isOn: $launchAtLogin)
                .onChange(of: launchAtLogin) { _, newValue in
                    LaunchAtLogin.set(newValue)
                    // Re-read the real state in case the call failed.
                    launchAtLogin = LaunchAtLogin.isEnabled
                }
            Divider()
            Menu("Debug") {
                Button("Copy Focused Window Info") {
                    appDelegate.copyFocusedWindowDiagnostics()
                }
                Button("Check for Updates…") {
                    updateChecker.check()
                }
            }
            Divider()
            Button("Quit WindowKit") {
                NSApplication.shared.terminate(nil)
            }
            .keyboardShortcut("q", modifiers: .command)
        } label: {
            Image(systemName: "rectangle.3.group")
                .symbolRenderingMode(.palette)
                .foregroundStyle(dotfunOrange)
                .task { updateChecker.start() }
        }
        .menuBarExtraStyle(.menu)
    }
}

enum LaunchAtLogin {
    static var isEnabled: Bool {
        SMAppService.mainApp.status == .enabled
    }

    static func set(_ enabled: Bool) {
        do {
            if enabled {
                if SMAppService.mainApp.status != .enabled {
                    try SMAppService.mainApp.register()
                }
            } else {
                if SMAppService.mainApp.status == .enabled {
                    try SMAppService.mainApp.unregister()
                }
            }
        } catch {
            NSLog("WindowKit: failed to update launch-at-login: \(error)")
        }
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
    private var staleGrantWindow: NSWindow?
    private var aboutWindow: NSWindow?
    private var cancellables = Set<AnyCancellable>()
    private var hotkeysArmed = false
    private var staleConfirmation: Task<Void, Never>?

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

        AccessibilityTrust.statePublisher(interval: 2.0)
            .receive(on: RunLoop.main)
            .sink { [weak self] state in
                guard let self else { return }
                switch state {
                case .functional:
                    self.cancelStaleConfirmation()
                    self.armHotkeys()
                    self.dismissOnboarding()
                    self.dismissStaleGrantWarning()
                case .denied:
                    self.cancelStaleConfirmation()
                    self.disarmHotkeys()
                    self.dismissStaleGrantWarning()
                    self.showOnboarding()
                case .stale:
                    // A single .stale reading is usually transient (a focused
                    // app momentarily failing the probe). Confirm it persists
                    // before disarming hotkeys or showing the warning, so we
                    // never flap the window or kill hotkeys on a blip.
                    self.confirmStaleThenReact()
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

    // MARK: - Stale-grant confirmation

    /// Wait out a confirmation window, then re-check live trust state; only
    /// react if it's *still* stale. Cancels itself if a `.functional`/`.denied`
    /// reading arrives first (see `cancelStaleConfirmation`).
    private func confirmStaleThenReact() {
        guard staleConfirmation == nil else { return } // already confirming
        staleConfirmation = Task { @MainActor [weak self] in
            try? await Task.sleep(for: .seconds(2.5))
            guard let self, !Task.isCancelled else { return }
            self.staleConfirmation = nil
            guard AccessibilityTrust.currentState() == .stale else { return }
            self.disarmHotkeys()
            self.dismissOnboarding()
            self.showStaleGrantWarning()
        }
    }

    private func cancelStaleConfirmation() {
        staleConfirmation?.cancel()
        staleConfirmation = nil
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

    private func showStaleGrantWarning() {
        guard staleGrantWindow == nil else {
            staleGrantWindow?.makeKeyAndOrderFront(nil)
            return
        }
        let view = StaleGrantView { [weak self] in
            self?.dismissStaleGrantWarning()
        }
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.title = "Accessibility Grant Out of Date"
        window.styleMask = [.titled, .closable]
        window.isReleasedWhenClosed = false
        window.setContentSize(NSSize(width: 500, height: 440))
        window.center()
        staleGrantWindow = window
        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func dismissStaleGrantWarning() {
        staleGrantWindow?.close()
        staleGrantWindow = nil
    }

    func copyFocusedWindowDiagnostics() {
        let report = FocusedWindowDiagnostics.snapshot()
        let pb = NSPasteboard.general
        pb.clearContents()
        pb.setString(report, forType: .string)
    }

    func openAbout(updateChecker: UpdateChecker) {
        if aboutWindow == nil {
            let hosting = NSHostingController(rootView: AboutView(updateChecker: updateChecker))
            let window = NSWindow(contentViewController: hosting)
            window.title = "About WindowKit"
            window.styleMask = [.titled, .closable]
            window.setContentSize(NSSize(width: 420, height: 360))
            window.isReleasedWhenClosed = false
            window.center()
            aboutWindow = window
        }
        NSApp.activate(ignoringOtherApps: true)
        aboutWindow?.makeKeyAndOrderFront(nil)
    }
}
