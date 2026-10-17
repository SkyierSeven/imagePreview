import AppKit
import SwiftUI

/// AppKit canvas: size is controlled only by display mode (+ rotation). No free zoom/pan.
struct ImageCanvasView: NSViewRepresentable {
    var image: CGImage?
    var pixelSize: CGSize
    var displayMode: DisplayMode
    var rotationDegrees: Double

    func makeNSView(context: Context) -> ModeImageView {
        ModeImageView()
    }

    func updateNSView(_ nsView: ModeImageView, context: Context) {
        nsView.apply(
            image: image,
            pixelSize: pixelSize,
            displayMode: displayMode,
            rotationDegrees: rotationDegrees
        )
    }
}

final class ModeImageView: NSView {
    private let imageLayer = CALayer()
    private var image: CGImage?
    private var pixelSize: CGSize = .zero
    private var displayMode: DisplayMode = .fit
    private var rotationDegrees: Double = 0

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        wantsLayer = true
        layer = CALayer()
        layer?.backgroundColor = NSColor(calibratedWhite: 0.12, alpha: 1).cgColor
        layer?.masksToBounds = true

        imageLayer.contentsGravity = .resize
        imageLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer?.addSublayer(imageLayer)
        focusRingType = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override var acceptsFirstResponder: Bool { true }

    override func layout() {
        super.layout()
        relayout()
    }

    func apply(
        image: CGImage?,
        pixelSize: CGSize,
        displayMode: DisplayMode,
        rotationDegrees: Double
    ) {
        self.image = image
        self.pixelSize = pixelSize
        self.displayMode = displayMode
        self.rotationDegrees = rotationDegrees
        imageLayer.contents = image
        relayout()
    }

    private func relayout() {
        guard image != nil, pixelSize.width > 0, pixelSize.height > 0, bounds.width > 0, bounds.height > 0 else {
            imageLayer.frame = .zero
            return
        }

        let rotated = abs(rotationDegrees.truncatingRemainder(dividingBy: 180)) == 90
        let contentSize = rotated
            ? CGSize(width: pixelSize.height, height: pixelSize.width)
            : pixelSize

        let drawSize = baseSize(for: contentSize, in: bounds.size)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        imageLayer.bounds = CGRect(origin: .zero, size: drawSize)
        imageLayer.position = CGPoint(x: bounds.midX, y: bounds.midY)
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

    override func mouseDown(with event: NSEvent) {
        window?.makeFirstResponder(self)
    }
}
