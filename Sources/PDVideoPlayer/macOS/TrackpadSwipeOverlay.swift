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
        private var scrubStateMachine = TrackpadScrubStateMachine()
        private var phaseLessEndTask: Task<Void, Never>?

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
            let actions = scrubStateMachine.handle(makeInput(from: event))
            if apply(actions) {
                return nil
            }
            return event
        }

        private func makeInput(from event: NSEvent) -> TrackpadScrubStateMachine.Input {
            TrackpadScrubStateMachine.Input(
                phase: TrackpadScrubStateMachine.Phase(eventPhase: event.phase),
                hasMomentum: !event.momentumPhase.isEmpty,
                deltaX: event.scrollingDeltaX,
                deltaY: event.scrollingDeltaY,
                isDirectionInvertedFromDevice: event.isDirectionInvertedFromDevice,
                hasPreciseDeltas: event.hasPreciseScrollingDeltas,
                currentTime: model.currentTime,
                duration: model.duration,
                isPlaying: model.isPlaying
            )
        }

        private func apply(_ actions: [TrackpadScrubStateMachine.Action]) -> Bool {
            guard !actions.isEmpty else { return false }
            for action in actions {
                switch action {
                case .pause:
                    model.pause()
                case .play:
                    model.play()
                case let .setTracking(value):
                    model.isTracking = value
                case let .setScrubbing(value):
                    model.isScrubbing = value
                case let .seek(time):
                    model.seekPrecisely(to: time)
                case let .snapSeek(time):
                    model.seekPrecisely(to: time)
                case let .schedulePhaseLessEnd(delayNanoseconds):
                    schedulePhaseLessEnd(after: delayNanoseconds)
                case .cancelPhaseLessEnd:
                    cancelPhaseLessEndTask()
                }
            }
            return true
        }

        private func schedulePhaseLessEnd(after delayNanoseconds: UInt64) {
            cancelPhaseLessEndTask()
            phaseLessEndTask = Task { @MainActor [weak self] in
                guard let self else { return }
                do {
                    try await Task.sleep(nanoseconds: delayNanoseconds)
                } catch {
                    return
                }
                guard !Task.isCancelled else { return }
                let actions = self.scrubStateMachine.handlePhaseLessEndTimeout()
                _ = self.apply(actions)
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

private extension TrackpadScrubStateMachine.Phase {
    init(eventPhase: NSEvent.Phase) {
        if eventPhase.contains(.ended) {
            self = .ended
        } else if eventPhase.contains(.cancelled) {
            self = .cancelled
        } else if eventPhase.contains(.began) {
            self = .began
        } else if eventPhase.contains(.changed) {
            self = .changed
        } else {
            self = .none
        }
    }
}
#endif
