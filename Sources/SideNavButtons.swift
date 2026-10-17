import SwiftUI

/// Left / right peek buttons that auto-hide after the mouse stops moving.
struct SideNavButtons: View {
    var canGoPrevious: Bool
    var canGoNext: Bool
    var visible: Bool
    var onPrevious: () -> Void
    var onNext: () -> Void

    var body: some View {
        HStack {
            navButton(
                systemName: "chevron.left",
                enabled: canGoPrevious,
                help: "上一张",
                action: onPrevious
            )
            Spacer()
            navButton(
                systemName: "chevron.right",
                enabled: canGoNext,
                help: "下一张",
                action: onNext
            )
        }
        .padding(.horizontal, 12)
        .opacity(visible ? 1 : 0)
        .allowsHitTesting(visible)
        .animation(.easeInOut(duration: 0.2), value: visible)
    }

    private func navButton(
        systemName: String,
        enabled: Bool,
        help: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 56)
                .background(Color.black.opacity(enabled ? 0.35 : 0.15), in: RoundedRectangle(cornerRadius: 8))
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
        .help(help)
    }
}

/// Reports mouse-moved activity inside the content area.
struct MouseActivityMonitor: NSViewRepresentable {
    var onActivity: () -> Void

    func makeNSView(context: Context) -> TrackingView {
        let view = TrackingView()
        view.onActivity = onActivity
        return view
    }

    func updateNSView(_ nsView: TrackingView, context: Context) {
        nsView.onActivity = onActivity
    }

    final class TrackingView: NSView {
        var onActivity: (() -> Void)?
        private var tracking: NSTrackingArea?

        override func updateTrackingAreas() {
            super.updateTrackingAreas()
            if let tracking {
                removeTrackingArea(tracking)
            }
            let options: NSTrackingArea.Options = [
                .mouseMoved,
                .mouseEnteredAndExited,
                .activeInKeyWindow,
                .inVisibleRect,
            ]
            let area = NSTrackingArea(rect: bounds, options: options, owner: self, userInfo: nil)
            addTrackingArea(area)
            tracking = area
        }

        override func mouseMoved(with event: NSEvent) {
            onActivity?()
        }

        override func mouseEntered(with event: NSEvent) {
            onActivity?()
        }
    }
}
