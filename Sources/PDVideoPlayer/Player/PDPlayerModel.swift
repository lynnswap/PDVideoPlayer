//
//  PDPlayerModel.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/16.
//

import SwiftUI
import AVFoundation
import AVKit
import Combine
#if canImport(UIKit)


enum SkipDirection {
    case backward
    case forward
}
@MainActor
@Observable public class PDPlayerModel: NSObject, DynamicProperty {
    public var isPlaying: Bool = false
    public var currentTime: Double = 0
    public var duration: Double = 0
    
    let slider = VideoPlayerSlider()
    
    public var isTracking = false
    public var isBuffering: Bool = false
    
    public var isLooping: Bool = true
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    
    public var player: AVPlayer
    @Environment(\.videoPlayerCloseAction) private var closeAction
    
    var doubleTapCount: Int = 0
    private var doubleTapBaseTime: Double = 0
    
    private var doubleTapResetTask: Task<(), Never>? = nil
    private var doubleTapDirection: SkipDirection? = nil
    let rippleStore = RippleEffectStore()
    public var scrollView = UIScrollView()
    public func update() {}
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        // タップ位置でリップルエフェクトだけ先に発火
        let location = recognizer.location(in: recognizer.view)
       
        
        guard let view = recognizer.view else { return }
        
        let viewWidth = view.bounds.width
        let tapX = location.x
        
        // 現在の再生位置
        let current = currentTime
        
        // ダブルタップの方向を判定 (左: 巻き戻し, 右: 早送り)
        let newDirection: SkipDirection = (tapX < viewWidth / 2) ? .backward : .forward
        
        // もし方向が変わったらリセットする (YouTube の挙動を想定)
        if doubleTapDirection != newDirection {
            // 新たに連続ダブルタップを開始
            doubleTapCount = 0
            doubleTapBaseTime = current
            doubleTapDirection = newDirection
        }
        
        // まだ direction が設定されていない初回タップの場合
        if doubleTapDirection == nil {
            doubleTapDirection = newDirection
            doubleTapBaseTime = current
        }
        
        // タップ回数を加算
        doubleTapCount += 1
        
        // 「最初にダブルタップした時刻(doubleTapBaseTime) から (10秒 * タップ回数)」進める/戻す
        let skipSeconds = Double(10 * doubleTapCount)
        
        // 実際にシークする先の秒数を計算
        let targetTime: Double
        switch doubleTapDirection {
        case .backward:
            targetTime = max(doubleTapBaseTime - skipSeconds, 0)  // 巻き戻し。0秒以下には行かないようにクリップ
        case .forward:
            targetTime = min(doubleTapBaseTime + skipSeconds, duration) // 早送り。duration超えないようにクリップ
        case .none:
            return
        }
        
        let labelSeconds:Int = targetTime > .zero ? Int(skipSeconds) : .zero
        rippleStore.addRipple(at: location,duration: labelSeconds)

        // シーク実行
        seek(to: targetTime)
        
        // 古いタスクがあればキャンセル (連続タップ用のタイマーリセット)
        doubleTapResetTask?.cancel()
        
        // 1秒後に「連続ダブルタップ状態」をリセットする
        doubleTapResetTask = Task { [weak self] in
            try? await Task.sleep(for:.seconds(1.2))
            guard !Task.isCancelled, let self = self else { return }

            self.doubleTapCount = 0
            self.doubleTapBaseTime = 0
            self.doubleTapDirection = nil
        }
    }
    
    private var timeObserverToken: Any?
    private var playerVC:AVPlayerViewController?
    public var isLongpress:Bool = false
    public init(
        url: URL
    ) {
        let player = AVPlayer(url: url)
        self.player = player
    }
    public init(
        player: AVPlayer
    ) {
        self.player = player
    }
    
    func setupPlayer(
    ) -> AVPlayerViewController{
        let vc = AVPlayerViewController()
        self.playerVC = vc
        let player = self.player
        vc.player = player
        player.appliesMediaSelectionCriteriaAutomatically = false
        
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self = self else { return }
                
                switch status {
                case .playing:
                    addPeriodicTimeObserver(player)
                    if !self.isPlaying{
                        self.isPlaying = true
                    }
                    if self.isBuffering{
                        self.isBuffering = false
                    }
                    
                case .paused:
                    removePeriodicTimeObserver(player)
                    if self.isPlaying,!self.isTracking{
                        self.isPlaying = false
                    }
                    if self.isBuffering{
                        self.isBuffering = false
                    }
                    
                case .waitingToPlayAtSpecifiedRate:
                    switch self.player.reasonForWaitingToPlay {
                    case .evaluatingBufferingRate, .toMinimizeStalls:
                        if !self.isBuffering{
                            self.isBuffering = true
                        }
                    default:
                        if self.isBuffering{
                            self.isBuffering = false
                        }
                    }
                    
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
        return vc
    }
    
    func addPeriodicTimeObserver(_ player:AVPlayer) {
        guard timeObserverToken == nil else { return }
        
        timeObserverToken = player.addPeriodicTimeObserver(
            forInterval: CMTime(value: 1, timescale: 30),
            queue: .main
        ) { [weak self] time in
            guard let self else { return }
            MainActor.assumeIsolated {
                guard let currentItem = self.player.currentItem else { return }
                let current = CMTimeGetSeconds(time)
                let total = CMTimeGetSeconds(currentItem.duration)
                
                self.currentTime = current
                if total.isFinite { self.duration = total }
                
                if !self.isTracking{
                    let ratio: Float = (self.duration > 0) ? Float(current / self.duration) : 0
                    self.slider.value = ratio
                }
            }
        }
    }
    private func removePeriodicTimeObserver(_ player:AVPlayer) {
        guard let timeObserverToken else { return }
        player.removeTimeObserver(timeObserverToken)
        self.timeObserverToken = nil
    }
    
    func play() {
        player.play()
    }
    
    func pause() {
        player.pause()
    }
    public func togglePlay(){
        if self.isPlaying {
            self.pause()
        } else {
            self.play()
        }
    }
    
    /// 動画全体の中で ratio(0～1) の位置へシーク
    public func seekRatio(_ ratio: Double) {
        let target = duration * ratio
        seek(to: target)
    }
    
    /// 秒指定でシーク
    public func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: time)
    }
    public func seekPrecisely(to seconds: Double) {
        let cm = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
        self.currentTime = seconds
    }
    
    var initialCenter = CGPoint()
    var isOnTheta: Bool = false
    var initialGesturePoint = CGPoint.zero
}

extension PDPlayerModel:UIGestureRecognizerDelegate{
    @objc public func handlePanGesture(_ recognizer: UIPanGestureRecognizer) {
        guard let scrollView = recognizer.view as? UIScrollView,
              let containerView = scrollView.viewWithTag(1) else { return }
        
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            recognizer.isEnabled = false
            return
        }
        
        switch recognizer.state {
        case .began:
            initialCenter = containerView.center
            let gestureStartPointInScrollView = recognizer.location(in: scrollView)
            let gestureStartPointInContainerView = scrollView.convert(gestureStartPointInScrollView, to: containerView)
            initialGesturePoint = CGPoint(x: containerView.center.x - gestureStartPointInContainerView.x,
                                          y: containerView.center.y - gestureStartPointInContainerView.y)
            containerView.setAnchorPoint(anchorPointInContainerView: gestureStartPointInContainerView, forView: scrollView)
        case .changed:
            let translation = recognizer.translation(in: scrollView)
            if isOnTheta || abs(translation.y) >= 20 {
                isOnTheta = true
                containerView.center = CGPoint(x: self.initialCenter.x + translation.x,
                                               y: self.initialCenter.y + translation.y)
                let angleFactor = self.initialGesturePoint.x > 0 ? -1.0 : 1.0
                let angle = min(translation.y / scrollView.bounds.height, 1.0) * CGFloat.pi / 4.0 * angleFactor
                containerView.transform = CGAffineTransform(rotationAngle: angle)
            }
        case .ended:
            isOnTheta = false
            let velocity = recognizer.velocity(in: scrollView)
            if abs(velocity.x) < abs(velocity.y) && abs(velocity.y) > 500 {
                let predictedEndCenter = CGPoint(
                    x: containerView.center.x + velocity.x * UIScrollView.DecelerationRate.normal.rawValue,
                    y: containerView.center.y + velocity.y * UIScrollView.DecelerationRate.normal.rawValue
                )
                let speed = abs(velocity.y) / scrollView.bounds.height
                var stoptime = (CGFloat(2.8) / speed)
                if stoptime > 2.5 {
                    stoptime = CGFloat(2.5)
                } else if stoptime < 0.2 {
                    stoptime = 0.2
                }
                closeAction?(stoptime * 0.5)
               
                UIView.animate(withDuration: stoptime, delay: 0, options: .curveLinear, animations: {
                    containerView.center = CGPoint(
                        x: self.initialCenter.x + predictedEndCenter.x,
                        y: self.initialCenter.y + predictedEndCenter.y
                    )
                    containerView.alpha = 0
                    let angleFactor = self.initialGesturePoint.x > 0 ? -1.0 : 1.0
                    let angle = min(predictedEndCenter.y / scrollView.bounds.height, 1.0) * CGFloat.pi / 3.0 * angleFactor
                    containerView.transform = CGAffineTransform(rotationAngle: angle)
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    containerView.transform = .identity
                    containerView.center = self.initialCenter
                })
            }
        default:
            break
        }
    }
    @objc public func handlePanGestureUpDown(_ recognizer: UIPanGestureRecognizer) {
        guard let scrollView = recognizer.view as? UIScrollView,
              let containerView = scrollView.viewWithTag(1) else { return }
        
        if scrollView.zoomScale > scrollView.minimumZoomScale {
            recognizer.isEnabled = false
            return
        }
        
        switch recognizer.state {
        case .began:
            initialCenter = containerView.center
        case .changed:
            let translation = recognizer.translation(in: scrollView)
            containerView.center = CGPoint(x: self.initialCenter.x  ,
                                           y: self.initialCenter.y + translation.y )
            
        case .ended:
            let velocity = recognizer.velocity(in: scrollView)
            if  abs(velocity.x) < abs(velocity.y) && abs(velocity.y) > 500 {

                let decelerationRate = UIScrollView.DecelerationRate.normal.rawValue

                // New code for predicting the end location after the drag ends
                let predictedEndCenter = CGPoint(
                    x: containerView.center.x + velocity.x * decelerationRate,
                    y: containerView.center.y + velocity.y * decelerationRate
                )
                let speed = abs(velocity.y) / scrollView.bounds.height
                var stoptime = (CGFloat(2.0) / speed)
                if stoptime > 2.0{
                    stoptime = CGFloat(2.5)
                } else if stoptime < 0.18{
                    stoptime = 0.15
                }
                closeAction?(stoptime * 0.5)
           
                UIView.animate(withDuration: stoptime, delay: 0, options: .curveLinear, animations: {
                    containerView.center = CGPoint(
                        x: self.initialCenter.x ,
                        y: self.initialCenter.y + predictedEndCenter.y)
                    containerView.alpha = 0
                })
            } else {
                UIView.animate(withDuration: 0.2, animations: {
                    containerView.transform = CGAffineTransform.identity
                    containerView.center = self.initialCenter
                })
            }

        default:
            break
        }
    }
    public func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        guard let scrollView = gestureRecognizer.view as? UIScrollView ,
              !self.isLongpress else { return false }
        
        if scrollView.zoomScale <= scrollView.minimumZoomScale {
            if let panGestureRecognizer = gestureRecognizer as? UIPanGestureRecognizer {
                let translation = panGestureRecognizer.translation(in: scrollView)
                return abs(translation.y) <= abs(translation.x)
            }
        }
        return scrollView.zoomScale <= scrollView.minimumZoomScale && !isOnTheta
    }
}
extension UIView {
    func setAnchorPoint(anchorPointInContainerView:CGPoint, forView view: UIView) {
        let anchorPoint = CGPoint(x: anchorPointInContainerView.x / view.bounds.width, y: anchorPointInContainerView.y / view.bounds.height)

        let newPoint = CGPoint(x: view.bounds.size.width * anchorPoint.x, y: view.bounds.size.height * anchorPoint.y)
        let oldPoint = CGPoint(x: view.bounds.size.width * view.layer.anchorPoint.x, y: view.bounds.size.height * view.layer.anchorPoint.y)

        var position = view.layer.position

        position.x -= oldPoint.x
        position.x += newPoint.x

        position.y -= oldPoint.y
        position.y += newPoint.y

        view.layer.position = position
        view.layer.anchorPoint = anchorPoint
    }
}
#endif
