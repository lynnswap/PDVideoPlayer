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

class VideoPlayerSlider: NSSlider {
    override var intrinsicContentSize: NSSize {
        let size = super.intrinsicContentSize
        return NSSize(width: size.width, height: size.height + 20)
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
