import SwiftUI

@main
struct imagePreviewApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @State private var model = ViewerModel()

    var body: some Scene {
        // Single window — reopening a file replaces content via AppDelegate / openURL.
        Window("imagePreview", id: "main") {
            ContentView(model: model)
                .onAppear {
                    appDelegate.model = model
                    openLaunchArgumentsIfNeeded()
                }
        }
        .defaultSize(width: 960, height: 640)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("打开…") {
                    openPanel()
                }
                .keyboardShortcut("o", modifiers: .command)
            }

            CommandMenu("显示") {
                Button("适应窗口") { model.setDisplayMode(.fit) }
                Button("填满窗口") { model.setDisplayMode(.fill) }
                Button("实际大小") { model.setDisplayMode(.actual) }
                Button("拉伸填满") { model.setDisplayMode(.stretch) }

                Divider()

                Button("放大") { model.zoomIn() }
                    .keyboardShortcut("=", modifiers: .command)
                Button("缩小") { model.zoomOut() }
                    .keyboardShortcut("-", modifiers: .command)
                Button("重置缩放") { model.resetZoom() }
                    .keyboardShortcut("0", modifiers: [.command])

                Divider()

                Button("顺时针旋转") { model.rotateClockwise() }
                    .keyboardShortcut("r", modifiers: .command)
                Button("逆时针旋转") { model.rotateCounterclockwise() }
                    .keyboardShortcut("r", modifiers: [.command, .shift])
            }

            CommandMenu("浏览") {
                Button("上一张") { model.goPrevious() }
                    .disabled(!(model.navigator?.canGoPrevious ?? false))
                Button("下一张") { model.goNext() }
                    .disabled(!(model.navigator?.canGoNext ?? false))
            }
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
