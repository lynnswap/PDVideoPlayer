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

        init(model: PDPlayerModel) { self.model = model }

        func startMonitoring() {
            monitor = NSEvent.addLocalMonitorForEvents(matching: .scrollWheel) { [weak self] event in
                guard
                    let self,
                    let view = self.overlay,
                    view.window != nil
                else { return event }

                let local = view.convert(event.locationInWindow, from: nil)

                if view.bounds.contains(local){
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
