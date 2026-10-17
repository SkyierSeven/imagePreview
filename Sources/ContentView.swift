import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var model: ViewerModel
    @Bindable private var shortcuts = ShortcutSettings.shared
    @Bindable private var reading = ReadingPreferences.shared

    @State private var sideControlsVisible = true
    @State private var hideSideControlsTask: Task<Void, Never>?
    @State private var showShortcutSettings = false

    private let sideControlsHideDelay: Duration = .seconds(2)

    private var rtl: Bool { reading.rightToLeft }

    var body: some View {
        ZStack {
            Color.black

            if let loaded = model.loadedImage {
                ImageCanvasView(
                    image: loaded.cgImage,
                    pixelSize: loaded.pixelSize,
                    displayMode: model.displayMode,
                    rotationDegrees: model.rotationDegrees,
                    onDoubleClick: { reading.toggleImmersive() }
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
                canGoLeading: rtl ? model.canGoNext : model.canGoPrevious,
                canGoTrailing: rtl ? model.canGoPrevious : model.canGoNext,
                visible: sideControlsVisible && model.navigator != nil,
                immersive: reading.immersive,
                leadingHelp: rtl ? "下一页" : "上一张",
                trailingHelp: rtl ? "上一页" : "下一张",
                onLeading: { model.navigateLeading(rtl: rtl) },
                onTrailing: { model.navigateTrailing(rtl: rtl) }
            )

            MouseActivityMonitor {
                bumpSideControls()
            }
            .allowsHitTesting(false)

            // Swipe left → next page, swipe right → previous (manga / Photos style).
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
        .background(
            WindowChromeConfigurator(
                fileURL: model.navigator?.currentURL,
                immersive: reading.immersive,
                onSystemExitFullscreen: { reading.exitImmersive() }
            )
        )
        .onDrop(of: [UTType.fileURL], isTargeted: nil, perform: handleDrop)
        .focusable()
        .focusEffectDisabled()
        .onAppear { bumpSideControls() }
        .onKeyPress(.leftArrow) {
            model.navigateLeading(rtl: rtl)
            return .handled
        }
        .onKeyPress(.rightArrow) {
            model.navigateTrailing(rtl: rtl)
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
        .onKeyPress(.escape) {
            if reading.immersive {
                reading.exitImmersive()
                return .handled
            }
            return .ignored
        }
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
            reading.toggleImmersive()
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
        .toolbar(reading.immersive ? .hidden : .automatic)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    Button {
                        reading.toggleImmersive()
                    } label: {
                        Label(
                            reading.immersive ? "退出沉浸" : "沉浸阅读",
                            systemImage: reading.immersive ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right"
                        )
                    }

                    Toggle(isOn: $reading.rightToLeft) {
                        Label("从右到左（日漫）", systemImage: "book.pages")
                    }

                    Divider()

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
                .help("沉浸、阅读方向、显示与快捷键")
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

/// Titlebar / fullscreen chrome driven by immersive mode.
private struct WindowChromeConfigurator: NSViewRepresentable {
    var fileURL: URL?
    var immersive: Bool
    var onSystemExitFullscreen: () -> Void

    func makeCoordinator() -> Coordinator {
        Coordinator(onSystemExitFullscreen: onSystemExitFullscreen)
    }

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        context.coordinator.installObservers()
        DispatchQueue.main.async { context.coordinator.apply(fileURL: fileURL, immersive: immersive, to: view.window) }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        context.coordinator.onSystemExitFullscreen = onSystemExitFullscreen
        DispatchQueue.main.async { context.coordinator.apply(fileURL: fileURL, immersive: immersive, to: nsView.window) }
    }

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.tearDown()
    }

    @MainActor
    final class Coordinator {
        var onSystemExitFullscreen: () -> Void
        private var exitObserver: NSObjectProtocol?
        private var lastImmersive: Bool?

        init(onSystemExitFullscreen: @escaping () -> Void) {
            self.onSystemExitFullscreen = onSystemExitFullscreen
        }

        func installObservers() {
            guard exitObserver == nil else { return }
            exitObserver = NotificationCenter.default.addObserver(
                forName: NSWindow.didExitFullScreenNotification,
                object: nil,
                queue: .main
            ) { [weak self] _ in
                MainActor.assumeIsolated {
                    self?.onSystemExitFullscreen()
                }
            }
        }

        func tearDown() {
            if let exitObserver {
                NotificationCenter.default.removeObserver(exitObserver)
                self.exitObserver = nil
            }
        }

        func apply(fileURL: URL?, immersive: Bool, to window: NSWindow?) {
            guard let window else { return }

            if window.representedURL != fileURL {
                window.representedURL = fileURL
            }

            let immersiveChanged = lastImmersive != immersive
            lastImmersive = immersive

            if immersive {
                window.titleVisibility = .hidden
                window.titlebarAppearsTransparent = true
                window.styleMask.insert(.fullSizeContentView)
                window.titlebarSeparatorStyle = .none
                if immersiveChanged, !window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            } else {
                window.titleVisibility = .visible
                window.titlebarAppearsTransparent = false
                window.toolbarStyle = .unifiedCompact
                window.titlebarSeparatorStyle = .line
                if window.styleMask.contains(.fullSizeContentView) {
                    window.styleMask.remove(.fullSizeContentView)
                }
                if immersiveChanged, window.styleMask.contains(.fullScreen) {
                    window.toggleFullScreen(nil)
                }
            }
        }
    }
}
