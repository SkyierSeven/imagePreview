import AppKit
import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
    @Bindable var model: ViewerModel

    var body: some View {
        ZStack {
            Color(nsColor: NSColor(calibratedWhite: 0.12, alpha: 1))
                .ignoresSafeArea()

            if let loaded = model.loadedImage {
                ImageCanvasView(
                    image: loaded.cgImage,
                    pixelSize: loaded.pixelSize,
                    displayMode: model.displayMode,
                    rotationDegrees: model.rotationDegrees,
                    userScale: model.userScale,
                    isCustomZoom: model.isCustomZoom,
                    onUserScaleChange: { scale in
                        model.isCustomZoom = scale != 1
                        model.userScale = scale
                        if scale == 1 {
                            model.isCustomZoom = false
                        }
                    }
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

            if model.isLoading {
                ProgressView()
                    .controlSize(.small)
                    .padding(8)
                    .background(.ultraThinMaterial, in: Capsule())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding()
            }
        }
        .frame(minWidth: 480, minHeight: 320)
        .background(WindowTitleUpdater(title: model.windowTitle))
        .onDrop(of: [UTType.fileURL], isTargeted: nil, perform: handleDrop)
        .focusable()
        .onKeyPress(.leftArrow) {
            model.goPrevious()
            return .handled
        }
        .onKeyPress(.rightArrow) {
            model.goNext()
            return .handled
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
        .onKeyPress(keys: [.init("="), .init("+")]) { _ in
            model.zoomIn()
            return .handled
        }
        .onKeyPress(keys: [.init("-")]) { _ in
            model.zoomOut()
            return .handled
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

/// Keeps the single NSWindow title in sync with the current file.
private struct WindowTitleUpdater: NSViewRepresentable {
    let title: String

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async { view.window?.title = title }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async { nsView.window?.title = title }
    }
}
