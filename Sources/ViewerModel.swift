import AppKit
import Foundation
import Observation

@MainActor
@Observable
final class ViewerModel {
    var navigator: DirectoryNavigator?
    var loadedImage: LoadedImage?
    var isLoading = false
    var errorMessage: String?

    /// Session-level view state — kept across next/prev and replace-open.
    var displayMode: DisplayMode = .fit
    var rotationDegrees: Double = 0
    var userScale: CGFloat = 1
    var isCustomZoom = false

    private var loadTask: Task<Void, Never>?
    private var generation = 0

    var windowTitle: String {
        guard let nav = navigator, let url = nav.currentURL else {
            return "imagePreview"
        }
        return "\(url.lastPathComponent) — \(nav.positionLabel)"
    }

    var hasImage: Bool { loadedImage != nil }

    func open(url: URL) {
        let standardized = url.standardizedFileURL
        guard SupportedFormats.isImageExtension(standardized) || SupportedFormats.canDecode(standardized) else {
            errorMessage = "无法打开：\(standardized.lastPathComponent)"
            return
        }

        navigator = DirectoryNavigator.build(around: standardized)
        errorMessage = nil
        // Keep displayMode + rotation; reset per-image zoom framing under current mode.
        isCustomZoom = false
        userScale = 1
        loadCurrent()
    }

    func goPrevious() {
        guard let next = navigator?.previous() else { return }
        navigator = next
        isCustomZoom = false
        userScale = 1
        loadCurrent()
    }

    func goNext() {
        guard let next = navigator?.next() else { return }
        navigator = next
        isCustomZoom = false
        userScale = 1
        loadCurrent()
    }

    func setDisplayMode(_ mode: DisplayMode) {
        displayMode = mode
        isCustomZoom = false
        userScale = 1
    }

    func rotateClockwise() {
        rotationDegrees = (rotationDegrees + 90).truncatingRemainder(dividingBy: 360)
    }

    func rotateCounterclockwise() {
        rotationDegrees = (rotationDegrees - 90).truncatingRemainder(dividingBy: 360)
        if rotationDegrees < 0 { rotationDegrees += 360 }
    }

    func zoomIn() {
        isCustomZoom = true
        userScale = min(userScale * 1.25, 32)
    }

    func zoomOut() {
        isCustomZoom = true
        userScale = max(userScale / 1.25, 0.05)
    }

    func resetZoom() {
        isCustomZoom = false
        userScale = 1
    }

    private func loadCurrent() {
        guard let url = navigator?.currentURL else {
            loadedImage = nil
            return
        }

        loadTask?.cancel()
        generation += 1
        let token = generation
        isLoading = true

        loadTask = Task { [weak self] in
            let image = await ImageLoader.load(url: url)
            guard let self, token == self.generation, !Task.isCancelled else { return }
            self.isLoading = false
            if let image {
                self.loadedImage = image
                self.errorMessage = nil
            } else {
                self.loadedImage = nil
                self.errorMessage = "无法解码：\(url.lastPathComponent)"
            }
        }
    }
}
