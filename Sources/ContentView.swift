import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var model: ViewerModel
    @Bindable private var shortcuts = ShortcutSettings.shared

    @State private var sideControlsVisible = true
    @State private var hideSideControlsTask: Task<Void, Never>?
    @State private var showShortcutSettings = false

    /// Idle seconds before side nav buttons fade out.
    private let sideControlsHideDelay: Duration = .seconds(2)

    var body: some View {
        ZStack {
            Color(nsColor: NSColor(calibratedWhite: 0.12, alpha: 1))

            if let loaded = model.loadedImage {
                ImageCanvasView(
                    image: loaded.cgImage,
                    pixelSize: loaded.pixelSize,
                    displayMode: model.displayMode,
                    rotationDegrees: model.rotationDegrees
                )
                .clipShape(Rectangle())
            } else {
                VStack(spacing: 12) {
                    Image(systemName: "photo.on.rectangle.angled")
                        .font(.system(size: 48))
                        .foregroundStyle(.secondary)
                    Text("拖入图片，或 ⌘O 打开")
                        .foregroundStyle(.secondary)
                    if let error = model.errorMessage {
                        Text(error)
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }
            }

            SideNavButtons(
                canGoPrevious: model.navigator?.canGoPrevious ?? false,
                canGoNext: model.navigator?.canGoNext ?? false,
                visible: sideControlsVisible && model.navigator != nil,
                onPrevious: { model.goPrevious() },
                onNext: { model.goNext() }
            )

            MouseActivityMonitor {
                bumpSideControls()
            }
            .allowsHitTesting(false)

            // Trackpad / Magic Mouse: one horizontal swipe → one image.
            SwipeNavigateMonitor(
                onPrevious: { model.goPrevious() },
                onNext: { model.goNext() }
            )
            .allowsHitTesting(false)

            if model.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(12)
            }
        }
        .frame(minWidth: 480, minHeight: 320)
        .navigationTitle(model.windowTitle)
        .background(WindowChromeConfigurator(fileURL: model.navigator?.currentURL))
        .onDrop(of: [UTType.fileURL], isTargeted: nil, perform: handleDrop)
        .focusable()
        .focusEffectDisabled()
        .onAppear { bumpSideControls() }
        // Built-in arrows — always on, not customizable / not removable.
        .onKeyPress(.leftArrow) {
            model.goPrevious()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            model.goNext()
            return .handled
        }
        .onKeyPress(.upArrow) {
            model.goPrevious()
            return .handled
        }
        .onKeyPress(.downArrow) {
            model.goNext()
            return .handled
        }
        // Extra user-defined shortcuts.
        .onKeyPress { press in
            if shortcuts.matchesPrevious(press) {
                model.goPrevious()
                return .handled
            }
            if shortcuts.matchesNext(press) {
                model.goNext()
                return .handled
            }
            return .ignored
        }
        .onKeyPress(keys: [.init("0")]) { _ in
            model.setDisplayMode(.fit)
            return .handled
        }
        .onKeyPress(keys: [.init("1")]) { _ in
            model.setDisplayMode(.actual)
            return .handled
        }
        .onKeyPress(keys: [.init("f")]) { _ in
            model.setDisplayMode(.fill)
            return .handled
        }
        .onKeyPress(keys: [.init("s")]) { _ in
            model.setDisplayMode(.stretch)
            return .handled
        }
        .onKeyPress(keys: [.init("r")]) { press in
            if press.modifiers.contains(.shift) {
                model.rotateCounterclockwise()
            } else {
                model.rotateClockwise()
            }
            return .handled
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Picker(
                        "显示模式",
                        selection: Binding(
                            get: { model.displayMode },
                            set: { model.setDisplayMode($0) }
                        )
                    ) {
                        ForEach(DisplayMode.allCases) { mode in
                            Label(mode.title, systemImage: mode.symbolName)
                                .tag(mode)
                                .help(mode.tip)
                        }
                    }

                    Divider()

                    Button {
                        model.rotateClockwise()
                    } label: {
                        Label("顺时针旋转", systemImage: "rotate.right")
                    }
                    .disabled(!model.hasImage)

                    Button {
                        model.rotateCounterclockwise()
                    } label: {
                        Label("逆时针旋转", systemImage: "rotate.left")
                    }
                    .disabled(!model.hasImage)

                    Divider()

                    Button("自定义切图快捷键…") {
                        showShortcutSettings = true
                    }
                } label: {
                    Text("更多")
                        .font(.system(size: 13))
                }
                .help("显示模式、旋转与快捷键")
                .menuIndicator(.hidden)
            }
        }
        .toolbarBackground(.visible, for: .windowToolbar)
        .toolbarBackground(Color(nsColor: NSColor.windowBackgroundColor), for: .windowToolbar)
        .sheet(isPresented: $showShortcutSettings) {
            ShortcutSettingsView(settings: shortcuts)
        }
    }

    private func bumpSideControls() {
        sideControlsVisible = true
        hideSideControlsTask?.cancel()
        hideSideControlsTask = Task { @MainActor in
            try? await Task.sleep(for: sideControlsHideDelay)
            guard !Task.isCancelled else { return }
            withAnimation(.easeInOut(duration: 0.2)) {
                sideControlsVisible = false
            }
        }
    }

    private func handleDrop(_ providers: [NSItemProvider]) -> Bool {
        guard let provider = providers.first else { return false }
        provider.loadItem(forTypeIdentifier: UTType.fileURL.identifier, options: nil) { item, _ in
            let url: URL? = {
                if let url = item as? URL { return url }
                if let data = item as? Data {
                    return URL(dataRepresentation: data, relativeTo: nil)
                }
                return nil
            }()
            guard let url else { return }
            Task { @MainActor in
                model.open(url: url)
            }
        }
        return true
    }
}

/// Configures titlebar chrome once; never writes `window.title` (avoids fighting SwiftUI).
private struct WindowChromeConfigurator: NSViewRepresentable {
    var fileURL: URL?

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { Self.apply(fileURL: fileURL, to: view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { Self.apply(fileURL: fileURL, to: nsView.window) }
    }

    private static func apply(fileURL: URL?, to window: NSWindow?) {
        guard let window else { return }
        window.titleVisibility = .visible
        window.titlebarAppearsTransparent = false
        window.toolbarStyle = .unifiedCompact
        window.titlebarSeparatorStyle = .line
        if window.styleMask.contains(.fullSizeContentView) {
            window.styleMask.remove(.fullSizeContentView)
        }
        if window.representedURL != fileURL {
            window.representedURL = fileURL
        }
    }
}
