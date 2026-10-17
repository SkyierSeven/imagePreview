import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate {
    var model: ViewerModel?

    func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    func application(_ application: NSApplication, open urls: [URL]) {
        guard let url = urls.first else { return }
        Task { @MainActor in
            model?.open(url: url)
            // Bring the single window forward instead of spawning another.
            if let window = NSApp.windows.first(where: { $0.isVisible }) ?? NSApp.windows.first {
                window.makeKeyAndOrderFront(nil)
            }
            NSApp.activate(ignoringOtherApps: true)
        }
    }

    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if !flag {
            NSApp.windows.first?.makeKeyAndOrderFront(nil)
        }
        return true
    }

    /// Prevent macOS from opening additional untitled windows for document opens.
    func applicationShouldOpenUntitledFile(_ sender: NSApplication) -> Bool {
        false
    }
}
