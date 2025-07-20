//
//  VideoPlayerSlider.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/16.
//

import SwiftUI
import AVFoundation
#if os(macOS)
import AppKit
class VideoPlayerSliderCell: NSSliderCell {
    public var knobDiameter: CGFloat = 12 {
        didSet {
            controlView?.needsLayout = true
            controlView?.needsDisplay = true
        }
    }
    private let barHeight:    CGFloat = 2
    var baseColor: NSColor = .white { didSet { controlView?.needsDisplay = true } }
    private var minColor: NSColor { baseColor.withAlphaComponent(0.8) }
    private var maxColor: NSColor { baseColor.withAlphaComponent(0.3) }
    private let verticalInset: CGFloat = 2

    override var trackRect: NSRect {
        guard let ctrl = controlView else { return .zero }

        let xInset  = knobDiameter / 2
        let isFlipped = ctrl.isFlipped

        let centerY: CGFloat = isFlipped
            ? ctrl.bounds.height - verticalInset - knobDiameter / 2
            : verticalInset + knobDiameter / 2

        return NSRect(
            x:      xInset,
            y:      centerY - barHeight / 2,
            width:  ctrl.bounds.width - knobDiameter,
            height: barHeight
        )
    }

    override func knobRect(flipped: Bool) -> NSRect {
        guard let ctrl = controlView else { return .zero }

        let track = self.trackRect
        let ratio = CGFloat((doubleValue - minValue) / (maxValue - minValue))
        let x     = track.minX + ratio * track.width - knobDiameter / 2

        let isFlipped = ctrl.isFlipped
        let originY: CGFloat = isFlipped
            ? ctrl.bounds.height - verticalInset - knobDiameter
            : verticalInset

        return NSRect(
            x: x.rounded(.toNearestOrAwayFromZero),
            y: originY.rounded(.toNearestOrAwayFromZero),
            width:  knobDiameter,
            height: knobDiameter
        )
    }

    override func drawBar(inside _: NSRect, flipped: Bool) {
        let track = self.trackRect
        maxColor.setFill()
        track.fill()

        let fraction = CGFloat(doubleValue - minValue) / CGFloat(maxValue - minValue)
        var played   = track
        played.size.width *= fraction
        minColor.setFill()
        played.fill()
    }
    override func drawKnob(_ knobRect: NSRect) {
        let path = NSBezierPath(ovalIn: knobRect)
        baseColor.setFill()
        path.fill()
    }
}
class VideoPlayerSlider: NSSlider {
    public var knobDiameter: CGFloat = 12 {
        didSet {
            if let cell = cell as? VideoPlayerSliderCell {
                cell.knobDiameter = knobDiameter
            }
        }
    }
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        cell = VideoPlayerSliderCell()
        if let cell = cell as? VideoPlayerSliderCell {
            cell.knobDiameter = knobDiameter
        }
        allowsTickMarkValuesOnly = false
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        cell = VideoPlayerSliderCell()
        if let cell = cell as? VideoPlayerSliderCell {
            cell.knobDiameter = knobDiameter
        }
    }
    var baseColor: NSColor {
        get { (cell as? VideoPlayerSliderCell)?.baseColor ?? .white }
        set { (cell as? VideoPlayerSliderCell)?.baseColor = newValue }
    }
    var onScroll: ((NSEvent.Phase, Double) -> Void)?

    /// Restrict drag interactions to within the knob's height while keeping
    /// scroll gestures active for the full height.
    override func hitTest(_ point: NSPoint) -> NSView? {
        if let event = NSApp.currentEvent {
            switch event.type {
            case .leftMouseDown, .leftMouseDragged, .leftMouseUp:
                if point.y > knobDiameter { return nil }
            default:
                break
            }
        }
        return super.hitTest(point)
    }
    override func wantsScrollEventsForSwipeTracking(on axis: NSEvent.GestureAxis) -> Bool {
        axis == .horizontal
    }
    override func scrollWheel(with event: NSEvent) {
        let phase = event.phase
        if phase == .ended || phase == .cancelled {
            onScroll?(phase, doubleValue)
            super.scrollWheel(with: event)
            return
        }

        if !event.momentumPhase.isEmpty { return }
        if abs(event.scrollingDeltaX) > abs(event.scrollingDeltaY),
           event.scrollingDeltaX != 0 || event.scrollingDeltaY != 0 {

            let sign: Double = event.isDirectionInvertedFromDevice ? 1 : -1
            let sensitivity: Double = event.hasPreciseScrollingDeltas ? 0.002 : 0.0003
            let next = doubleValue + event.scrollingDeltaX * sign * sensitivity
            doubleValue = min(max(next, minValue), maxValue)

            if !phase.isEmpty {
                onScroll?(phase, doubleValue)
            }
            if phase != .changed {
                super.scrollWheel(with: event)
            }
            return
        }

        super.scrollWheel(with: event)
    }
}

#else
class VideoPlayerSlider: UISlider {
    weak var viewModel:PDPlayerModel?
    private var tapOffset: CGFloat = 0
    
    /// ドラッグ開始
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
#if swift(>=6.2)
        if #unavailable(iOS 26.0, macOS 26.0) {
            let location = touch.location(in: self)
            let fraction = CGFloat((value - minimumValue) / (maximumValue - minimumValue))
            let thumbX = fraction * bounds.width
            tapOffset = location.x - thumbX
        }
#else
        let location = touch.location(in: self)
        let fraction = CGFloat((value - minimumValue) / (maximumValue - minimumValue))
        let thumbX = fraction * bounds.width
        tapOffset = location.x - thumbX
#endif
        
        guard let viewModel else { return true }
      
        wasPlayingBeforeTracking = viewModel.isPlaying
        viewModel.isTracking = true
        if viewModel.isPlaying {
            viewModel.pause()
        }
        
        return true
    }
    
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
#if swift(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *) {
            return super.continueTracking(touch, with: event)
        }else{
            return updateLegacyTracking(touch)
        }
#else
        return updateLegacyTracking(touch)
#endif
    }

    private func updateLegacyTracking(_ touch: UITouch) -> Bool {
        let location = touch.location(in: self)

        // 1. 「タップ座標 - オフセット」を thumb の中心とみなす
        let sliderWidth = bounds.width
        let newThumbX = location.x - tapOffset

        // 2. 0～スライダー幅 にクランプ
        let clampedX = min(max(0, newThumbX), sliderWidth)

        // 3. [0..1] の範囲に換算
        let fraction = clampedX / sliderWidth
        let newValue = (maximumValue - minimumValue) * Float(fraction) + minimumValue

        // 4. value を更新してイベント送出 (.valueChanged)
        if self.value != newValue {
            self.value = newValue
            sendActions(for: .valueChanged)
        }

        // 継続する
        return true
    }
    
    /// ドラッグ終了
    override func endTracking(_ touch: UITouch?, with event: UIEvent?) {
        super.endTracking(touch, with: event)
        self.endTracking()
    }
    
    /// ドラッグがキャンセルされたとき
    override func cancelTracking(with event: UIEvent?) {
        super.cancelTracking(with: event)
        self.endTracking()
    }
    
    private func endTracking(){
#if swift(>=6.2)
        if #unavailable(iOS 26.0, macOS 26.0) {
            tapOffset = 0
        }
#else
        tapOffset = 0
#endif
        guard let viewModel else { return }
        viewModel.isTracking = false
        if wasPlayingBeforeTracking {
            viewModel.play()
        }
    }
    
    override var intrinsicContentSize: CGSize {
#if swift(>=6.2)
        if #available(iOS 26.0, macOS 26.0, *) {
            return super.intrinsicContentSize
        } else {
            let size = super.intrinsicContentSize
            return CGSize(width: size.width, height: size.height + 40)
        }
#else
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: size.height + 40)
#endif
    }
    private var wasPlayingBeforeTracking = false
    
    @objc func onValueChanged(_ sender: UISlider) {
        guard let viewModel else { return }
        guard viewModel.duration > 0 else { return }
        
        
        let total = viewModel.duration
        let rawSeconds = Double(sender.value) * total
        let step = 0.03
        let snappedSeconds = (rawSeconds / step).rounded() * step
        if !sender.isTracking {
            let snappedRatio = snappedSeconds / total
            sender.value = Float(snappedRatio)
        }
        viewModel.seekPrecisely(to: snappedSeconds)
    }
    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let viewModel else { return }
        switch gesture.state {
        case .began:
            viewModel.isTracking = true
            wasPlayingBeforeTracking = viewModel.isPlaying
            if wasPlayingBeforeTracking {
                viewModel.pause()
            }
        case .changed:
            let translation = gesture.translation(in: self)
            let deltaX = Float(translation.x)
            let sensitivity: Float = 0.001
            let newValue = self.value + deltaX * sensitivity
            let clampedValue = min(max(newValue, self.minimumValue), self.maximumValue)
            self.value = clampedValue
            gesture.setTranslation(.zero, in: self)
            if viewModel.duration > 0 {
                let total = viewModel.duration
                let currentSeconds = Double(self.value) * total
                viewModel.seekPrecisely(to: currentSeconds)
            }
        case .ended, .cancelled, .failed:
            viewModel.isTracking = false
            if viewModel.duration > 0 {
                let total = viewModel.duration
                let rawSeconds = Double(self.value) * total
                let step = 0.03
                let snappedSeconds = (rawSeconds / step).rounded() * step
                let snappedRatio = snappedSeconds / total
                self.value = Float(snappedRatio)
                viewModel.seekPrecisely(to: snappedSeconds)
            }
            if wasPlayingBeforeTracking {
                viewModel.play()
            }
        default:
            break
        }
    }


}
#endif
