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
        private var phaseLessEndTask: Task<Void, Never>?
        private let phaseLessEndDelayNanoseconds: UInt64 = 200_000_000

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
            cancelPhaseLessEndTask()
        }

        private func handleScroll(_ event: NSEvent) -> NSEvent? {
            guard model.duration > 0 else { return event }

            let isPhaseLess = event.phase.isEmpty
            let isEnded = event.phase == .ended || event.phase == .cancelled
            let isHorizontal = abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY)

            if isEnded {
                if isScrubbing {
                    finishScrubbing()
                    return nil
                }
                return event
            }

            if !event.momentumPhase.isEmpty { return event }

            if !isScrubbing {
                guard isHorizontal else { return event }
                beginScrubbing()
            }

            if isHorizontal {
                updateScrubbing(with: event)
            }

            if isPhaseLess {
                schedulePhaseLessEnd()
            } else {
                cancelPhaseLessEndTask()
            }
            return nil
        }

        private func beginScrubbing() {
            ratioValue = model.currentTime / model.duration
            wasPlayingBeforeScroll = model.isPlaying
            model.pause()
            model.isTracking = true
            model.isScrubbing = true
            isScrubbing = true
        }

        private func updateScrubbing(with event: NSEvent) {
            let sign: Double = event.isDirectionInvertedFromDevice ? 1 : -1
            let sensitivity: Double = event.hasPreciseScrollingDeltas ? 0.002 : 0.0003
            ratioValue = min(max(ratioValue + event.scrollingDeltaX * sign * sensitivity, 0), 1)
            model.seekPrecisely(to: ratioValue * model.duration)
        }

        private func finishScrubbing() {
            guard isScrubbing else { return }
            cancelPhaseLessEndTask()
            let total = model.duration
            let step  = 0.03
            let snapped = (ratioValue * total / step).rounded() * step
            model.seekPrecisely(to: snapped)
            model.isTracking = false
            model.isScrubbing = false
            if wasPlayingBeforeScroll { model.play() }
            isScrubbing = false
        }

        private func schedulePhaseLessEnd() {
            cancelPhaseLessEndTask()
            phaseLessEndTask = Task { @MainActor [weak self] in
                guard let self else { return }
                try? await Task.sleep(nanoseconds: self.phaseLessEndDelayNanoseconds)
                self.finishScrubbing()
            }
        }

        private func cancelPhaseLessEndTask() {
            phaseLessEndTask?.cancel()
            phaseLessEndTask = nil
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
