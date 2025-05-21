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

final class VideoPlayerSliderCell: NSSliderCell {
    private let knobDiameter: CGFloat = 12
    private let barHeight: CGFloat = 2
    private let minColor = NSColor.white.withAlphaComponent(0.8)
    private let maxColor = NSColor.white.withAlphaComponent(0.3)

    override var trackRect: NSRect {
        guard let ctrl = controlView else { return .zero }

        let inset = knobDiameter / 2
        let y = (ctrl.bounds.height - barHeight) / 2

        return NSRect(
            x: inset,
            y: y,
            width: ctrl.bounds.width - knobDiameter,
            height: barHeight
        )
    }
    override func drawBar(inside _: NSRect, flipped: Bool) {
        let track = self.trackRect
        maxColor.setFill()
        track.fill()
        let fraction = CGFloat(doubleValue - minValue) / CGFloat(maxValue - minValue)
        var played = track
        played.size.width *= fraction
        minColor.setFill()
        played.fill()
    }
    override func drawKnob(_ knobRect: NSRect) {
        let path = NSBezierPath(ovalIn: knobRect)
        minColor.setFill()
        path.fill()
    }
    override func knobRect(flipped: Bool) -> NSRect {
        guard let ctrl = controlView else { return .zero }

        let track = self.trackRect
        let ratio = CGFloat((doubleValue - minValue) / (maxValue - minValue))

        let x = track.minX + ratio * track.width - knobDiameter / 2
        let y = (ctrl.bounds.height - knobDiameter) / 2

        return NSRect(
            x: x.rounded(.toNearestOrAwayFromZero),
            y: y.rounded(.toNearestOrAwayFromZero),
            width: knobDiameter,
            height: knobDiameter
        )
    }
}

class VideoPlayerSlider: NSSlider {
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        cell = VideoPlayerSliderCell()
        allowsTickMarkValuesOnly = false
    }
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        cell = VideoPlayerSliderCell()
    }
    override var intrinsicContentSize: NSSize {
        let s = super.intrinsicContentSize
        return .init(width: s.width, height: 20)
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
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: size.height + 40)
    }

}
#endif
