import SwiftUI

@main
struct imagePreviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = ViewerModel()

    var body: some Scene {
        Window(model.windowTitle, id: "main") {
            ContentView(model: model)
                .onAppear {
                    appDelegate.model = model
                    openLaunchArgumentsIfNeeded()
                }
        }
        .defaultSize(width: 960, height: 640)
        .windowToolbarStyle(.unifiedCompact)
        // SwiftUI CommandsBuilder accepts a limited number of children per block.
        .commands {
            CommandGroup(replacing: .appInfo) {
                Button(String(localized: "about_app")) {
                    NSApp.orderFrontStandardAboutPanel(nil)
                }
            }

            CommandGroup(replacing: .appVisibility) {
                Button(String(localized: "hide_app")) {
                    NSApp.hide(nil)
                }
                .keyboardShortcut("h", modifiers: .command)

                Button(String(localized: "hide_others")) {
                    NSApp.hideOtherApplications(nil)
                }
                .keyboardShortcut("h", modifiers: [.command, .option])

                Button(String(localized: "show_all")) {
                    NSApp.unhideAllApplications(nil)
                }
            }

            CommandGroup(replacing: .appTermination) {
                Button(String(localized: "quit_app")) {
                    NSApp.terminate(nil)
                }
                .keyboardShortcut("q", modifiers: .command)
            }

            CommandGroup(replacing: .newItem) {
                Button(String(localized: "open…")) {
                    openPanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandGroup(replacing: .help) {
                Button(String(localized: "app_help")) {}
            }
        }
        .commands {
            CommandGroup(replacing: .saveItem) {}
            CommandGroup(replacing: .printItem) {}
            CommandGroup(replacing: .undoRedo) {}
            CommandGroup(replacing: .pasteboard) {}
            CommandGroup(replacing: .textEditing) {}
            CommandGroup(replacing: .textFormatting) {}
            CommandGroup(replacing: .toolbar) {}
            CommandGroup(replacing: .sidebar) {}
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
        panel.title = String(localized: "open_image_title")
        panel.message = String(localized: "open_image_message")
        panel.prompt = String(localized: "open_image_prompt")
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = SupportedFormats.contentTypes
        panel.begin { response in
            guard response == .OK, let url = panel.url else { return }
            model.open(url: url)
        }
    }
}
