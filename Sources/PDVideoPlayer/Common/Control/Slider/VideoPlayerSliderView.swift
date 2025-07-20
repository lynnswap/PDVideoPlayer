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
            foregroundColor: foregroundColor
        )
#if os(iOS)
        .onChange(of: knobSize) {
            updateThumb(size: knobSize, color: foregroundColor)
        }
        .onChange(of: foregroundColor) {
            updateThumb(size: knobSize, color: foregroundColor)
        }
#else
        .onChange(of: knobSize) {
            viewModel.slider.knobDiameter = knobSize
        }
        .onChange(of: foregroundColor) {
            viewModel.slider.baseColor = NSColor(foregroundColor)
        }
#endif
    }

#if os(iOS)
    private func updateThumb(size: CGFloat, color: Color) {
        let slider = viewModel.slider
        let config = UIImage.SymbolConfiguration(
            pointSize: size,
            weight: .regular,
            scale: .default
        )
        let leftColor = UIColor(color.opacity(0.8))
        let rightColor = UIColor(color.opacity(0.3))
        let thumbImage = UIImage(systemName: "circle.fill", withConfiguration: config)?
            .withTintColor(leftColor, renderingMode: .alwaysOriginal)
        slider.setThumbImage(thumbImage, for: .normal)
        slider.minimumTrackTintColor = leftColor
        slider.maximumTrackTintColor = rightColor
    }
#endif
}


#if os(macOS)
struct VideoPlayerSliderRepresentable: NSViewRepresentable {
    var viewModel: PDPlayerModel
    var knobSize: CGFloat
    var foregroundColor: Color

    func makeNSView(context: Context) -> NSSlider {
        let slider = viewModel.slider
        slider.knobDiameter = knobSize
        slider.baseColor = NSColor(foregroundColor)
        slider.minValue = 0
        slider.maxValue = 1
        slider.doubleValue = 0
        slider.isContinuous = true
        slider.target = context.coordinator
        slider.action = #selector(Coordinator.onValueChanged(_:))
        slider.onScroll = { phase, value in
            context.coordinator.handleScroll(phase: phase, ratioValue: value)
        }
        return slider
    }

    func updateNSView(_ nsView: NSSlider, context: Context) {}

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
                snapAndSeek(to: sender.doubleValue)
                if wasPlayingBeforeTracking {
                    viewModel.play()
                }
            default:
                break
            }
        }

        private func snapAndSeek(to ratio: Double) {
            let total   = viewModel.duration
            let step    = 0.03
            let seconds = (ratio * total / step).rounded() * step
            viewModel.seekPrecisely(to: seconds)
            viewModel.slider.doubleValue = seconds / total
        }

        private func seek(to ratio: Double) {
            let total = viewModel.duration
            viewModel.seekPrecisely(to: ratio * total)
        }

        func handleScroll(phase: NSEvent.Phase, ratioValue: Double) {
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
                snap(to: ratioValue)
            default:
                break
            }
        }

        private func snap(to ratioValue: Double) {
            let total = viewModel.duration
            let step  = 0.03
            let snapped = (ratioValue * total / step).rounded() * step
            viewModel.seekPrecisely(to: snapped)
            viewModel.slider.doubleValue = snapped / total
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

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel)
    }

    func makeUIView(context: Context) -> UISlider {
        let slider = viewModel.slider
        let config = UIImage.SymbolConfiguration(
            pointSize: knobSize,
            weight: .regular,
            scale: .default
        )
        let leftColor = UIColor(foregroundColor.opacity(0.8))
        let rightColor = UIColor(foregroundColor.opacity(0.3))
        let thumbImage = UIImage(systemName: "circle.fill", withConfiguration: config)?
            .withTintColor(leftColor, renderingMode: .alwaysOriginal)
        slider.setThumbImage(thumbImage, for: .normal)
        slider.minimumTrackTintColor = leftColor
        slider.maximumTrackTintColor = rightColor
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        slider.isContinuous = true
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.onValueChanged(_:)),
            for: .valueChanged
        )
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.touchDown(_:)),
            for: .touchDown
        )
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.touchUp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
        let gesture = UIPanGestureRecognizer(
            target: context.coordinator,
            action: #selector(Coordinator.handlePan(_:))
        )
        gesture.allowedScrollTypesMask = [.continuous, .discrete]
        gesture.minimumNumberOfTouches = 2
        gesture.maximumNumberOfTouches = 2
        slider.addGestureRecognizer(gesture)
        return slider
    }

    func updateUIView(_ uiView: UISlider, context: Context) {}

    @MainActor
    class Coordinator: NSObject {
        var viewModel: PDPlayerModel
        private var wasPlayingBeforeTracking = false

        init(_ viewModel: PDPlayerModel) {
            self.viewModel = viewModel
        }

        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let slider = viewModel.slider
            switch gesture.state {
            case .began:
                viewModel.isTracking = true
                wasPlayingBeforeTracking = viewModel.isPlaying
                if wasPlayingBeforeTracking {
                    viewModel.pause()
                }
            case .changed:
                let translation = gesture.translation(in: slider)
                let deltaX = Float(translation.x)
                let sensitivity: Float = 0.001
                let newValue = slider.value + deltaX * sensitivity
                let clampedValue = min(max(newValue, slider.minimumValue), slider.maximumValue)
                slider.value = clampedValue
                gesture.setTranslation(.zero, in: slider)
                if viewModel.duration > 0 {
                    let total = viewModel.duration
                    let currentSeconds = Double(slider.value) * total
                    viewModel.seekPrecisely(to: currentSeconds)
                }
            case .ended, .cancelled, .failed:
                viewModel.isTracking = false
                if viewModel.duration > 0 {
                    let total = viewModel.duration
                    let rawSeconds = Double(slider.value) * total
                    let step = 0.03
                    let snappedSeconds = (rawSeconds / step).rounded() * step
                    let snappedRatio = snappedSeconds / total
                    slider.value = Float(snappedRatio)
                    viewModel.seekPrecisely(to: snappedSeconds)
                }
                if wasPlayingBeforeTracking {
                    viewModel.play()
                }
            default:
                break
            }
        }

        @objc func touchDown(_ sender: UISlider) {
            guard viewModel.duration > 0 else { return }
            viewModel.isTracking = true
            wasPlayingBeforeTracking = viewModel.isPlaying
            if wasPlayingBeforeTracking {
                viewModel.pause()
            }
        }

        @objc func touchUp(_ sender: UISlider) {
            guard viewModel.duration > 0 else { return }
            viewModel.isTracking = false
            let total = viewModel.duration
            let rawSeconds = Double(sender.value) * total
            let step = 0.03
            let snappedSeconds = (rawSeconds / step).rounded() * step
            let snappedRatio = snappedSeconds / total
            sender.value = Float(snappedRatio)
            viewModel.seekPrecisely(to: snappedSeconds)
            if wasPlayingBeforeTracking {
                viewModel.play()
            }
        }

        @objc func onValueChanged(_ sender: UISlider) {
            guard viewModel.duration > 0 else { return }
            let total = viewModel.duration
            let rawSeconds = Double(sender.value) * total
            let step = 0.03
            let snappedSeconds = (rawSeconds / step).rounded() * step
            viewModel.seekPrecisely(to: snappedSeconds)
        }
    }
}
#endif

