import SwiftUI
import AVFoundation
#if os(macOS)
import AppKit
#endif

/// Wrapper view that hosts the platform specific slider and responds to
/// environment changes.
public struct VideoPlayerSliderView: View {
    var viewModel: PDPlayerModel
    @Environment(\.videoPlayerForegroundColor) private var foregroundColor
    @Environment(\.videoPlayerSliderKnobSize) private var knobSize

    public init(viewModel: PDPlayerModel) {
        self.viewModel = viewModel
    }

    public var body: some View {
        VideoPlayerSliderRepresentable(
            viewModel: viewModel,
            knobSize: knobSize,
            foregroundColor: foregroundColor,
            currentTime: viewModel.currentTime,
            duration: viewModel.duration,
            isTracking: viewModel.isTracking,
            isScrubbing: viewModel.isScrubbing
        )
    }
}


#if os(macOS)
struct VideoPlayerSliderRepresentable: NSViewRepresentable {
    var viewModel: PDPlayerModel
    var knobSize: CGFloat
    var foregroundColor: Color
    var currentTime: Double
    var duration: Double
    var isTracking: Bool
    var isScrubbing: Bool

    func makeNSView(context: Context) -> NSSlider {
        let slider = VideoPlayerSlider()
        slider.knobDiameter = knobSize
        slider.baseColor = NSColor(foregroundColor)
        slider.minValue = 0
        slider.maxValue = 1
        slider.doubleValue = 0
        slider.isContinuous = true
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.onValueChanged(_:))
        slider.onScroll = { [weak slider] phase, value in
            guard let slider else { return }
            context.coordinator.handleScroll(phase: phase, ratioValue: value, slider: slider)
        }
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context: Context) {
        guard let slider = nsView as? VideoPlayerSlider else { return }
        slider.knobDiameter = knobSize
        slider.baseColor = NSColor(foregroundColor)
        if duration > 0, (!isTracking || isScrubbing) {
            slider.doubleValue = currentTime / duration
        } else if duration <= 0, (!isTracking || isScrubbing) {
            slider.doubleValue = 0
        }
    }

    static func dismantleNSView(_ nsView: NSSlider, coordinator: Coordinator) {
        if let slider = nsView as? VideoPlayerSlider {
            slider.onScroll = nil
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel)
    }

    @MainActor
    class Coordinator: NSObject {
        var viewModel: PDPlayerModel
        private var wasPlayingBeforeTracking = false
        private var wasPlayingBeforeScroll = false
        init(_ viewModel: PDPlayerModel) {
            self.viewModel = viewModel
        }

        @objc func onValueChanged(_ sender: NSSlider) {
            guard viewModel.duration > 0,
                  let event = NSApp.currentEvent else { return }

            switch event.type {
            case .leftMouseDown:
                viewModel.isTracking = true
                wasPlayingBeforeTracking = viewModel.isPlaying
                viewModel.pause()
            case .leftMouseDragged:
                seek(to: sender.doubleValue)
            case .leftMouseUp:
                viewModel.isTracking = false
                snapAndSeek(sender, to: sender.doubleValue)
                if wasPlayingBeforeTracking {
                    viewModel.play()
                }
            default:
                break
            }
        }

        private func snapAndSeek(_ slider: NSSlider, to ratio: Double) {
            let total   = viewModel.duration
            let step    = 0.03
            let seconds = (ratio * total / step).rounded() * step
            viewModel.seekPrecisely(to: seconds)
            slider.doubleValue = seconds / total
        }

        private func seek(to ratio: Double) {
            let total = viewModel.duration
            viewModel.seekPrecisely(to: ratio * total)
        }

        func handleScroll(phase: NSEvent.Phase, ratioValue: Double, slider: NSSlider) {
            guard viewModel.duration > 0 else { return }
            let total = viewModel.duration

            switch phase {
            case .began:
                wasPlayingBeforeScroll = viewModel.isPlaying
                viewModel.pause()
                viewModel.isTracking = true
            case .changed:
                viewModel.seekPrecisely(to: ratioValue * total)
            case .ended, .cancelled:
                snap(slider, to: ratioValue)
            default:
                break
            }
        }

        private func snap(_ slider: NSSlider, to ratioValue: Double) {
            let total = viewModel.duration
            let step  = 0.03
            let snapped = (ratioValue * total / step).rounded() * step
            viewModel.seekPrecisely(to: snapped)
            slider.doubleValue = snapped / total
            viewModel.isTracking = false
            if wasPlayingBeforeScroll { viewModel.play() }
        }
    }
}
#else
import UIKit
struct VideoPlayerSliderRepresentable: UIViewRepresentable {
    var viewModel: PDPlayerModel
    var knobSize: CGFloat
    var foregroundColor: Color
    var currentTime: Double
    var duration: Double
    var isTracking: Bool
    var isScrubbing: Bool

    func makeUIView(context: Context) -> UISlider {
        let slider = VideoPlayerSlider()
        slider.viewModel = viewModel
        context.coordinator.updateAppearanceIfNeeded(
            for: slider,
            knobSize: knobSize,
            foregroundColor: foregroundColor
        )
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.isContinuous = true
        if #available(iOS 26.0, *) {
            slider.sliderStyle = .thumbless
        }
        slider.addTarget(
            slider,
            action: #selector(VideoPlayerSlider.onValueChanged(_:)),
            for: .valueChanged
        )
        let gesture = UIPanGestureRecognizer(
            target: slider,
            action: #selector(VideoPlayerSlider.handlePan(_:))
        )
        gesture.allowedScrollTypesMask = [.continuous, .discrete]
        gesture.minimumNumberOfTouches = 2
        gesture.maximumNumberOfTouches = 2
        slider.addGestureRecognizer(gesture)
        return slider
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func updateUIView(_ uiView: UISlider, context: Context) {
        guard let slider = uiView as? VideoPlayerSlider else { return }
        slider.viewModel = viewModel
        context.coordinator.updateAppearanceIfNeeded(
            for: slider,
            knobSize: knobSize,
            foregroundColor: foregroundColor
        )
        if duration > 0, (!isTracking || isScrubbing) {
            slider.value = Float(currentTime / duration)
        } else if duration <= 0, (!isTracking || isScrubbing) {
            slider.value = 0
        }
    }

    final class Coordinator {
        private var lastKnobSize: CGFloat?
        private var lastForegroundColor: UIColor?

        func updateAppearanceIfNeeded(
            for slider: UISlider,
            knobSize: CGFloat,
            foregroundColor: Color
        ) {
            let uiColor = UIColor(foregroundColor)
            if lastKnobSize == knobSize, lastForegroundColor?.isEqual(uiColor) == true {
                return
            }
            lastKnobSize = knobSize
            lastForegroundColor = uiColor

            let config = UIImage.SymbolConfiguration(
                pointSize: knobSize,
                weight: .regular,
                scale: .default
            )
            let leftColor = uiColor.withAlphaComponent(0.8)
            let rightColor = uiColor.withAlphaComponent(0.3)
            let thumbImage = UIImage(systemName: "circle.fill", withConfiguration: config)?
                .withTintColor(leftColor, renderingMode: .alwaysOriginal)
            slider.setThumbImage(thumbImage, for: .normal)
            slider.minimumTrackTintColor = leftColor
            slider.maximumTrackTintColor = rightColor
        }
    }
}
#endif
