import AppKit
import SwiftUI

/// AppKit canvas: pan / pinch / scroll-wheel zoom with display modes + rotation.
struct ImageCanvasView: NSViewRepresentable {
    var image: CGImage?
    var pixelSize: CGSize
    var displayMode: DisplayMode
    var rotationDegrees: Double
    var userScale: CGFloat
    var isCustomZoom: Bool
    var onUserScaleChange: (CGFloat) -> Void

    func makeNSView(context: Context) -> ZoomableImageView {
        let view = ZoomableImageView()
        view.onUserScaleChange = onUserScaleChange
        return view
    }

    func updateNSView(_ nsView: ZoomableImageView, context: Context) {
        nsView.onUserScaleChange = onUserScaleChange
        nsView.apply(
            image: image,
            pixelSize: pixelSize,
            displayMode: displayMode,
            rotationDegrees: rotationDegrees,
            userScale: userScale,
            isCustomZoom: isCustomZoom
        )
    }
}

final class ZoomableImageView: NSView {
    var onUserScaleChange: ((CGFloat) -> Void)?

    private let imageLayer = CALayer()
    private var image: CGImage?
    private var pixelSize: CGSize = .zero
    private var displayMode: DisplayMode = .fit
    private var rotationDegrees: Double = 0
    private var userScale: CGFloat = 1
    private var isCustomZoom = false

    private var magnifyGesture: NSMagnificationGestureRecognizer!
    private var panGesture: NSPanGestureRecognizer!
    private var lastMagnification: CGFloat = 1

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 1).cgColor

        imageLayer.contentsGravity = .resize
        imageLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer?.addSublayer(imageLayer)

        magnifyGesture = NSMagnificationGestureRecognizer(target: self, action: #selector(handleMagnify(_:)))
        addGestureRecognizer(magnifyGesture)

        panGesture = NSPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var acceptsFirstResponder: Bool { true }

    override func layout() {
        super.layout()
        relayout(preserveOffset: true)
    }

    override func scrollWheel(with event: NSEvent) {
        if event.modifierFlags.contains(.option) || abs(event.scrollingDeltaY) > 0 {
            let factor: CGFloat = event.scrollingDeltaY > 0 ? 1.08 : (1 / 1.08)
            adjustScale(by: factor)
        } else {
            super.scrollWheel(with: event)
        }
    }

    func apply(
        image: CGImage?,
        pixelSize: CGSize,
        displayMode: DisplayMode,
        rotationDegrees: Double,
        userScale: CGFloat,
        isCustomZoom: Bool
    ) {
        let imageChanged = self.image !== image
        let modeChanged = self.displayMode != displayMode || self.rotationDegrees != rotationDegrees
        self.image = image
        self.pixelSize = pixelSize
        self.displayMode = displayMode
        self.rotationDegrees = rotationDegrees
        self.userScale = userScale
        self.isCustomZoom = isCustomZoom

        imageLayer.contents = image
        relayout(preserveOffset: !(imageChanged || modeChanged) && isCustomZoom)
    }

    private func relayout(preserveOffset: Bool) {
        guard let _ = image, pixelSize.width > 0, pixelSize.height > 0, bounds.width > 0, bounds.height > 0 else {
            imageLayer.frame = .zero
            return
        }

        let rotated = abs(rotationDegrees.truncatingRemainder(dividingBy: 180)) == 90
        let contentSize = rotated
            ? CGSize(width: pixelSize.height, height: pixelSize.width)
            : pixelSize

        let base = baseSize(for: contentSize, in: bounds.size)
        let drawSize = CGSize(width: base.width * userScale, height: base.height * userScale)

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        var position = imageLayer.position
        if !preserveOffset || imageLayer.bounds.width == 0 {
            position = center
        }

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageLayer.bounds = CGRect(origin: .zero, size: drawSize)
        imageLayer.position = position
        imageLayer.setAffineTransform(CGAffineTransform(rotationAngle: CGFloat(rotationDegrees * .pi / 180)))
        CATransaction.commit()
    }

    private func baseSize(for content: CGSize, in container: CGSize) -> CGSize {
        switch displayMode {
        case .fit:
            let scale = min(container.width / content.width, container.height / content.height)
            return CGSize(width: content.width * scale, height: content.height * scale)
        case .fill:
            let scale = max(container.width / content.width, container.height / content.height)
            return CGSize(width: content.width * scale, height: content.height * scale)
        case .actual:
            return content
        case .stretch:
            return container
        }
    }

    private func adjustScale(by factor: CGFloat) {
        let next = min(max(userScale * factor, 0.05), 32)
        userScale = next
        isCustomZoom = true
        onUserScaleChange?(next)
        relayout(preserveOffset: true)
    }

    @objc private func handleMagnify(_ gesture: NSMagnificationGestureRecognizer) {
        switch gesture.state {
        case .began:
            lastMagnification = 0
        case .changed:
            let delta = gesture.magnification - lastMagnification
            lastMagnification = gesture.magnification
            adjustScale(by: 1 + delta)
        case .ended, .cancelled:
            lastMagnification = 0
        default:
            break
        }
    }

    @objc private func handlePan(_ gesture: NSPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageLayer.position = CGPoint(
            x: imageLayer.position.x + translation.x,
            y: imageLayer.position.y + translation.y
        )
        CATransaction.commit()
        gesture.setTranslation(.zero, in: self)
    }

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
        if event.clickCount == 2 {
            onUserScaleChange?(1)
        }
    }
}
