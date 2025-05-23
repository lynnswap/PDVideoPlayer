//
//  PDPlayerModel.swift
//  PDVideoPlayer
//
//  Created by Kazuki Nakashima on 2025/02/16.
//

#if os(macOS)
import AppKit
#endif
import SwiftUI
@preconcurrency import AVFoundation
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
    public var onClose: VideoPlayerCloseAction?
    
    var doubleTapCount: Int = 0
    private var doubleTapBaseTime: Double = 0
    
    private var doubleTapResetTask: Task<(), Never>? = nil
    private var doubleTapDirection: SkipDirection? = nil
    let rippleStore = RippleEffectStore()
    public var scrollView = UIScrollView()
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
        
        // Reset if the direction changes to mimic common video app behavior
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
    public var originalRate: Float = 1.0
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
        if duration > 0 && (currentTime >= duration || (duration - currentTime) < 0.1) {
            seek(to: 0)
        }
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
    
    // MARK: - Keyboard Navigation Support
    func stepFrames(by count: Int) {
        pause()
        player.currentItem?.step(byCount: count)
        if let current = player.currentItem?.currentTime() {
            currentTime = CMTimeGetSeconds(current)
        }
    }
    
    private var rateIndex: Int = 0
    private let rateValues: [Float] = [1, 2, 4, 8, 16]
    private var isRewind: Bool = false
    
    func cycleForwardRate() {
        if isRewind { rateIndex = 0; isRewind = false }
        rateIndex = min(rateIndex + 1, rateValues.count - 1)
        player.rate = rateValues[rateIndex]
        isPlaying = true
    }
    
    func cycleRewindRate() {
        if !isRewind { rateIndex = 0; isRewind = true }
        rateIndex = min(rateIndex + 1, rateValues.count - 1)
        player.rate = -rateValues[rateIndex]
        isPlaying = true
    }
    
    var initialCenter = CGPoint()
    var isRotatingGestureActive: Bool = false
    var initialGesturePoint = CGPoint.zero
    
    private var subtitleGroup: AVMediaSelectionGroup?
    public var subtitleOptions: [AVMediaSelectionOption] = []
    public var selectedSubtitle: AVMediaSelectionOption? {
        didSet { Task { await applySelectedSubtitle() } }
    }
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
            if isRotatingGestureActive || abs(translation.y) >= 20 {
                isRotatingGestureActive = true
                containerView.center = CGPoint(x: self.initialCenter.x + translation.x,
                                               y: self.initialCenter.y + translation.y)
                let angleFactor = self.initialGesturePoint.x > 0 ? -1.0 : 1.0
                let angle = min(translation.y / scrollView.bounds.height, 1.0) * CGFloat.pi / 4.0 * angleFactor
                containerView.transform = CGAffineTransform(rotationAngle: angle)
            }
        case .ended:
            isRotatingGestureActive = false
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
                onClose?(stoptime * 0.5)
               
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
                onClose?(stoptime * 0.5)
           
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
        return scrollView.zoomScale <= scrollView.minimumZoomScale && !isRotatingGestureActive
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



#if os(macOS)
@MainActor
@Observable public class PDPlayerModel: NSObject, DynamicProperty {
    public var isPlaying: Bool = false
    public var currentTime: Double = 0
    public var duration: Double = 0

    let slider = VideoPlayerSlider()
    public var isTracking = false
    public var isBuffering: Bool = false
    
    public var player: AVPlayer
    public var onClose: VideoPlayerCloseAction?
    public var originalRate: Float = 1.0
    /// When true, dragging on the player view moves the window.
    public var windowDraggable: Bool = false
    public var scrollView = PlayerScrollView()

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    private var timeObserverToken: Any?

    public init(url: URL) {
        self.player = AVPlayer(url: url)
    }

    public init(player: AVPlayer) {
        self.player = player
    }

    private var playerView: PlayerNSView?
    func setupPlayerView() -> PlayerNSView {
        let view = PlayerNSView()
        view.model = self
        view.isWindowDraggable = windowDraggable
        self.playerView = view
       
        view.setPlayer(player, videoGravity: .resizeAspect)
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .playing:
                    addPeriodicTimeObserver()
                    self.isPlaying = true
                case .paused:
                    removePeriodicTimeObserver()
                    self.isPlaying = false
                default:
                    break
                }
            }
            .store(in: &cancellables)

        if let item = player.currentItem {
            duration = CMTimeGetSeconds(item.duration)
        }
        return view
    }

    private func addPeriodicTimeObserver() {
        guard timeObserverToken == nil else { return }
        timeObserverToken = player.addPeriodicTimeObserver(forInterval: CMTime(value: 1, timescale: 30), queue: .main) { [weak self] time in
            guard let self else { return }
            MainActor.assumeIsolated {
                currentTime = CMTimeGetSeconds(time)
                if let item = player.currentItem {
                    let total = CMTimeGetSeconds(item.duration)
                    if total.isFinite { duration = total }
                }
                if !self.isTracking {
                    let ratio = (self.duration > 0) ? self.currentTime / self.duration : 0
                    self.slider.doubleValue = ratio
                }
            }
        }
    }

    private func removePeriodicTimeObserver() {
        if let token = timeObserverToken {
            player.removeTimeObserver(token)
            timeObserverToken = nil
        }
    }

    func play() {
        if duration > 0 && (currentTime >= duration || (duration - currentTime) < 0.1) {
            seek(to: 0)
        }
        player.play()
    }
    func pause() { player.pause() }

    public func togglePlay() {
        isPlaying ? pause() : play()
    }

    public func seekRatio(_ ratio: Double) {
        let target = duration * ratio
        seek(to: target)
    }

    public func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: time)
    }

    public func seekPrecisely(to seconds: Double) {
        let cm = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
        currentTime = seconds
    }

    // MARK: - Keyboard Navigation Support
    func stepFrames(by count: Int) {
        pause()
        player.currentItem?.step(byCount: count)
        if let current = player.currentItem?.currentTime() {
            currentTime = CMTimeGetSeconds(current)
        }
    }

    private var rateIndex: Int = 0
    private let rateValues: [Float] = [1, 2, 4, 8, 16]
    private var isRewind: Bool = false

    func cycleForwardRate() {
        if isRewind { rateIndex = 0; isRewind = false }
        rateIndex = min(rateIndex + 1, rateValues.count - 1)
        player.rate = rateValues[rateIndex]
        isPlaying = true
    }

    func cycleRewindRate() {
        if !isRewind { rateIndex = 0; isRewind = true }
        rateIndex = min(rateIndex + 1, rateValues.count - 1)
        player.rate = -rateValues[rateIndex]
        isPlaying = true
    }
    
    private var subtitleGroup: AVMediaSelectionGroup?
    public var subtitleOptions: [AVMediaSelectionOption] = []
    public var selectedSubtitle: AVMediaSelectionOption? {
        didSet { Task { await applySelectedSubtitle() } }
    }
}
#endif

extension PDPlayerModel{
    public func loadSubtitleOptions() async {
        guard let item = player.currentItem else { return }
        do {
            guard let group = try await item.asset.loadMediaSelectionGroup(for: .legible) else {
                self.subtitleGroup  = nil
                self.subtitleOptions = []
                self.selectedSubtitle = nil
                return
            }
            self.subtitleGroup  = group
            self.subtitleOptions = group.options
            self.selectedSubtitle = item.currentMediaSelection.selectedMediaOption(in: group)
        } catch {
#if DEBUG
            print("⚠️ subtitle group load failed:", error)
#endif
        }
    }
    private func applySelectedSubtitle() async {
        guard let item = player.currentItem,
              let group = subtitleGroup else { return }
        item.select(selectedSubtitle, in: group)
    }
}
