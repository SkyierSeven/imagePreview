import SwiftUI

@main
struct imagePreviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = ViewerModel()

    var body: some Scene {
        // Title comes from ContentView.navigationTitle(model.windowTitle).
        Window(model.windowTitle, id: "main") {
            ContentView(model: model)
                .onAppear {
                    appDelegate.model = model
                    openLaunchArgumentsIfNeeded()
                }
        }
        .defaultSize(width: 960, height: 640)
        .windowToolbarStyle(.unifiedCompact)
        .commands {
            // Keep Open; strip unused system editing / view / help clutter.
            CommandGroup(replacing: .newItem) {
                Button("打开…") {
                    openPanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }
            CommandGroup(replacing: .saveItem) {}
            CommandGroup(replacing: .printItem) {}
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(replacing: .textEditing) {}
            CommandGroup(replacing: .textFormatting) {}
            CommandGroup(replacing: .toolbar) {}
            CommandGroup(replacing: .sidebar) {}
            CommandGroup(replacing: .help) {}
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "*"))
    }

    private func openLaunchArgumentsIfNeeded() {
        let args = CommandLine.arguments.dropFirst()
        for arg in args {
            if arg.hasPrefix("-") { continue }
            let url = URL(fileURLWithPath: arg)
            if FileManager.default.fileExists(atPath: url.path) {
                model.open(url: url)
                break
            }
        }
    }

    private func openPanel() {
        let panel = NSOpenPanel()
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = SupportedFormats.contentTypes
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            model.open(url: url)
        }
    }
}
