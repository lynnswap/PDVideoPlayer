//
//  VideoPlayerSliderView.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/16.
//

import SwiftUI
import AVFoundation
#if os(macOS)
#else
public struct VideoPlayerSliderView: UIViewRepresentable {
    var viewModel: PDPlayerModel
    
    public init(
        viewModel:PDPlayerModel
    ){
        self.viewModel = viewModel
    }
    
    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
  
    
    public func makeUIView(context: Context) -> UISlider {
        let slider = viewModel.slider

        
        let config = UIImage.SymbolConfiguration(
            pointSize: 6,
            weight: .regular,
            scale: .default
        )
        
        let leftColor:UIColor = UIColor(Color.white.opacity(0.8))
        let rightColor:UIColor = UIColor(Color.white.opacity(0.3))
        
        let thumbImage = UIImage(systemName: "circle.fill", withConfiguration: config)?
            .withTintColor(leftColor, renderingMode: .alwaysOriginal)
        slider.setThumbImage(thumbImage, for: .normal)
        
        slider.minimumTrackTintColor = leftColor
        slider.maximumTrackTintColor = rightColor
        
        slider.minimumValue = 0
        slider.maximumValue = 1
        slider.value = 0
        
        // ドラッグ中も連続で valueChanged が呼ばれる
        slider.isContinuous = true
        slider.addTarget(
            context.coordinator,
            action: #selector(Coordinator.onValueChanged(_:)),
            for: .valueChanged
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
    
    public func updateUIView(_ uiView: UISlider, context: Context) {
    }
    
    // MARK: - Coordinator
    
    @MainActor
    public class Coordinator: NSObject {
        var parent: VideoPlayerSliderView
        
        /// ドラッグ開始前に「再生中」だったかどうか
        private var wasPlayingBeforeTracking = false
        
        init(_ parent: VideoPlayerSliderView) {
            self.parent = parent
        }
        @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
            let slider = parent.viewModel.slider
            
            switch gesture.state {
            case .began:
                parent.viewModel.isTracking = true
                        
                wasPlayingBeforeTracking = parent.viewModel.isPlaying
                if wasPlayingBeforeTracking {
                    parent.viewModel.pause()
                }
                
            case .changed:
                // 移動量の計算
                let translation = gesture.translation(in: slider)
                let deltaX = Float(translation.x)
                let sensitivity: Float = 0.001
                let newValue = slider.value + deltaX * sensitivity
                let clampedValue = min(max(newValue, slider.minimumValue), slider.maximumValue)
                
                // スライダーの値を更新
                slider.value = clampedValue
                
                // 累積しないよう、毎回の移動量をリセット
                gesture.setTranslation(.zero, in: slider)
                
                // 動画の「途中プレビュー」をしたい場合
                if parent.viewModel.duration > 0 {
                    let total = parent.viewModel.duration
                    let currentSeconds = Double(slider.value) * total
                    parent.viewModel.seekPrecisely(to: currentSeconds)
                }
                
            case .ended, .cancelled, .failed:
                // 最終的な値を 30ms刻みなどでスナップ
                parent.viewModel.isTracking = false
                if parent.viewModel.duration > 0 {
                    let total = parent.viewModel.duration
                    let rawSeconds = Double(slider.value) * total
                    
                    let step = 0.03
                    let snappedSeconds = (rawSeconds / step).rounded() * step
                    let snappedRatio = snappedSeconds / total
                    
                    slider.value = Float(snappedRatio)
                    parent.viewModel.seekPrecisely(to: snappedSeconds)
                }
                
                // もともと再生中だったなら再開
                if wasPlayingBeforeTracking {
                    parent.viewModel.play()
                }
                
            default:
                break
            }
        }
        
        @objc func onValueChanged(_ sender: UISlider) {
            guard parent.viewModel.duration > 0 else { return }
            
            // 前回の状態を保持
            let wasTracking = parent.viewModel.isTracking
            // 現在の状態を更新
            parent.viewModel.isTracking = sender.isTracking
            
            // ---- 状態遷移を検知 ----
            
            // (A) ドラッグ開始: false -> true
            if wasTracking == false && parent.viewModel.isTracking == true {
                // 「再生中だったか」を覚えておく
                wasPlayingBeforeTracking = parent.viewModel.isPlaying
                // 一時停止
                parent.viewModel.pause()
            }
            
            // (B) ドラッグ終了: true -> false
            if wasTracking == true && parent.viewModel.isTracking == false {
                // もともと再生していたなら再開
                if wasPlayingBeforeTracking {
                    parent.viewModel.play()
                }
            }
            
            // ---- シーク処理 ----
            
            let total = parent.viewModel.duration
            let rawSeconds = Double(sender.value) * total
            
            // 30ms 刻み (0.03秒) で丸め
            let step = 0.03
            let snappedSeconds = (rawSeconds / step).rounded() * step
            
            // ドラッグ終了後だけスライダーをスナップ表示したい例
            if !sender.isTracking {
                let snappedRatio = snappedSeconds / total
                sender.value = Float(snappedRatio)
            }
            
            // 精密シーク
            parent.viewModel.seekPrecisely(to: snappedSeconds)
        }
    }
}
#endif
