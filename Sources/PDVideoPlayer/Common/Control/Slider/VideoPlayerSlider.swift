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

    private var tapOffset: CGFloat = 0
    
    /// ドラッグ開始
    override func beginTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
        let location = touch.location(in: self)
        let fraction = CGFloat((value - minimumValue) / (maximumValue - minimumValue))
        let thumbX = fraction * bounds.width
        tapOffset = location.x - thumbX
        return true
    }
    
    /// ドラッグ継続 (指を動かしている間)
    override func continueTracking(_ touch: UITouch, with event: UIEvent?) -> Bool {
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
        tapOffset = 0
        super.endTracking(touch, with: event)
    }
    
    /// ドラッグがキャンセルされたとき
    override func cancelTracking(with event: UIEvent?) {
        tapOffset = 0
        super.cancelTracking(with: event)
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

}
#endif
