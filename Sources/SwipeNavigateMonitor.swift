import AppKit
import SwiftUI

/// Trackpad / Magic Mouse horizontal swipe → exactly one image per gesture.
/// Fingers swipe left → next; swipe right → previous (same as Photos).
struct SwipeNavigateMonitor: NSViewRepresentable {
    var onPrevious: () -> Void
    var onNext: () -> Void

    func makeNSView(context: Context) -> NSView {
        SwipeNavigateController.shared.setHandlers(onPrevious: onPrevious, onNext: onNext)
        SwipeNavigateController.shared.start()
        return NSView()
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        SwipeNavigateController.shared.setHandlers(onPrevious: onPrevious, onNext: onNext)
    }
}

/// Single process-wide scroll monitor so SwiftUI view refreshes cannot stack listeners.
@MainActor
final class SwipeNavigateController {
    static let shared = SwipeNavigateController()

    private var onPrevious: (() -> Void)?
    private var onNext: (() -> Void)?
    private var monitor: Any?
    /// Fired once while the finger stays down; clears when the finger lifts.
    private var locked = false
    private var accumulated: CGFloat = 0
    private var unlockTask: Task<Void, Never>?

    private let threshold: CGFloat = 24
    /// Fallback only for devices that don't report scroll phases (e.g. some mice).
    private let discreteIdleUnlock: Duration = .milliseconds(180)

    private init() {}

    func setHandlers(onPrevious: @escaping () -> Void, onNext: @escaping () -> Void) {
        self.onPrevious = onPrevious
        self.onNext = onNext
    }

    func start() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { event in
            MainActor.assumeIsolated {
                SwipeNavigateController.shared.handle(event)
            }
            return event
        }
    }

    private func handle(_ event: NSEvent) {
        // Momentum is leftover from the same swipe — never switch on it, and unlock when it ends.
        if event.momentumPhase != [] {
            if event.momentumPhase == .ended || event.momentumPhase == .cancelled {
                clearLock()
            }
            return
        }

        // Finger up → ready for the next swipe immediately (no long pause).
        if event.phase == .ended || event.phase == .cancelled {
            clearLock()
            return
        }

        let dx = event.scrollingDeltaX
        let dy = event.scrollingDeltaY
        guard abs(dx) > abs(dy) * 1.2, abs(dx) > 0.35 else { return }

        // Still touching after one switch — ignore until lift.
        if locked { return }

        accumulated += dx

        if accumulated <= -threshold {
            fireNext(hasPhases: event.phase != [])
        } else if accumulated >= threshold {
            firePrevious(hasPhases: event.phase != [])
        }
    }

    private func fireNext(hasPhases: Bool) {
        locked = true
        accumulated = 0
        onNext?()
        if !hasPhases { scheduleDiscreteUnlock() }
    }

    private func firePrevious(hasPhases: Bool) {
        locked = true
        accumulated = 0
        onPrevious?()
        if !hasPhases { scheduleDiscreteUnlock() }
    }

    private func clearLock() {
        unlockTask?.cancel()
        unlockTask = nil
        locked = false
        accumulated = 0
    }

    private func scheduleDiscreteUnlock() {
        unlockTask?.cancel()
        unlockTask = Task { @MainActor in
            try? await Task.sleep(for: discreteIdleUnlock)
            guard !Task.isCancelled else { return }
            clearLock()
        }
    }
}
