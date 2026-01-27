#if os(macOS)
import SwiftUI

private final class PassThroughView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

public struct TrackpadSwipeOverlay: NSViewRepresentable {
    @Environment(PDPlayerModel.self) private var model
    public init() {}
    @MainActor
    public final class Coordinator {
        var model: PDPlayerModel
        weak var overlay: NSView?
        var monitor: Any?
        private var wasPlayingBeforeScroll = false
        private var isScrubbing = false
        private var ratioValue: Double = 0

        init(model: PDPlayerModel) { self.model = model }

        func startMonitoring() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard
                    let self,
                    let view = self.overlay,
                    let window = view.window,
                    event.window == window
                else { return event }

                let local = view.convert(event.locationInWindow, from: nil)

                if view.bounds.contains(local) {
                    return self.handleScroll(event)
                }
                return event
            }
        }

        func stopMonitoring() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }

        private func handleScroll(_ event: NSEvent) -> NSEvent? {
            guard model.duration > 0 else { return event }

            if !event.momentumPhase.isEmpty { return event }
            if abs(event.scrollingDeltaX) <= abs(event.scrollingDeltaY),
               event.scrollingDeltaX == 0 && event.scrollingDeltaY == 0 {
                return event
            }

            if event.phase == .began || (!isScrubbing && event.phase != .ended && event.phase != .cancelled) {
                ratioValue = model.currentTime / model.duration
                wasPlayingBeforeScroll = model.isPlaying
                model.pause()
                model.isTracking = true
                model.isScrubbing = true
                isScrubbing = true
            }

            let sign: Double = event.isDirectionInvertedFromDevice ? 1 : -1
            let sensitivity: Double = event.hasPreciseScrollingDeltas ? 0.002 : 0.0003
            ratioValue = min(max(ratioValue + event.scrollingDeltaX * sign * sensitivity, 0), 1)
            model.seekPrecisely(to: ratioValue * model.duration)

            if event.phase == .ended || event.phase == .cancelled {
                let total = model.duration
                let step  = 0.03
                let snapped = (ratioValue * total / step).rounded() * step
                model.seekPrecisely(to: snapped)
                model.isTracking = false
                model.isScrubbing = false
                if wasPlayingBeforeScroll { model.play() }
                isScrubbing = false
            }
            return nil
        }
    }

    public func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    public func makeNSView(context: Context) -> NSView {
        let v = PassThroughView()
        context.coordinator.overlay = v
        context.coordinator.startMonitoring()
        return v
    }

    public func updateNSView(_ nsView: NSView, context: Context) {}

    public static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stopMonitoring()
    }
}

public extension View {
    /// Places an invisible overlay to enlarge the trackpad swipe area
    /// for scrubbing with two fingers.
    func trackpadSwipeOverlay() -> some View {
        overlay(TrackpadSwipeOverlay())
    }
}
#endif
