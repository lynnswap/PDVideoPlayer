#if os(macOS)
import SwiftUI

private final class PassThroughView: NSView {
    override func hitTest(_ point: NSPoint) -> NSView? { nil }
}

struct TrackpadSwipeOverlay: NSViewRepresentable {
    @Environment(PDPlayerModel.self) private var model

    @MainActor
    final class Coordinator {
        var model: PDPlayerModel
        weak var overlay: NSView?
        var monitor: Any?

        init(model: PDPlayerModel) { self.model = model }

        func startMonitoring() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard
                    let self,
                    let view = self.overlay,
                    view.window != nil
                else { return event }

                let local = view.convert(event.locationInWindow, from: nil)

                if view.bounds.contains(local),
                   abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY) {
                    self.model.slider.scrollWheel(with: event)
                    return nil
                }
                return event
            }
        }

        func stopMonitoring() {
            if let monitor { NSEvent.removeMonitor(monitor) }
            monitor = nil
        }
    }

    func makeCoordinator() -> Coordinator { Coordinator(model: model) }

    func makeNSView(context: Context) -> NSView {
        let v = PassThroughView()
        context.coordinator.overlay = v
        context.coordinator.startMonitoring()
        return v
    }

    func updateNSView(_ nsView: NSView, context: Context) {}

    static func dismantleNSView(_ nsView: NSView, coordinator: Coordinator) {
        coordinator.stopMonitoring()
    }
}

public extension View {
    /// Enables trackpad swipe seeking using the provided player model.
    func trackpadSeeking() -> some View {
        overlay(TrackpadSwipeOverlay())
    }
}
#endif
