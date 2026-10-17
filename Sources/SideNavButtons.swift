import SwiftUI

/// Left / right peek buttons that auto-hide after the mouse stops moving.
struct SideNavButtons: View {
    var canGoLeading: Bool
    var canGoTrailing: Bool
    var visible: Bool
    var immersive: Bool
    var leadingHelp: String
    var trailingHelp: String
    var onLeading: () -> Void
    var onTrailing: () -> Void

    var body: some View {
        HStack {
            navButton(
                systemName: "chevron.left",
                enabled: canGoLeading,
                help: leadingHelp,
                action: onLeading
            )
            Spacer()
            navButton(
                systemName: "chevron.right",
                enabled: canGoTrailing,
                help: trailingHelp,
                action: onTrailing
            )
        }
        .padding(.horizontal, immersive ? 6 : 12)
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
                .font(.system(size: immersive ? 14 : 18, weight: .semibold))
                .foregroundStyle(.white.opacity(immersive ? 0.85 : 1))
                .frame(width: immersive ? 28 : 36, height: immersive ? 48 : 56)
                .background(
                    Color.black.opacity(immersive ? (enabled ? 0.22 : 0.08) : (enabled ? 0.35 : 0.15)),
                    in: RoundedRectangle(cornerRadius: immersive ? 6 : 8)
                )
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
