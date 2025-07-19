#if os(macOS)
import AppKit
#endif
import SwiftUI
@preconcurrency import AVFoundation
import AVKit
import Combine

#if os(iOS)
enum SkipDirection {
    case backward
    case forward
}
#endif

@MainActor
@Observable
public class PDPlayerModel: NSObject, DynamicProperty {
    // MARK: - Common Properties
    public var isPlaying: Bool = false
    public var currentTime: Double = 0
    public var duration: Double = 0

    let slider = VideoPlayerSlider()
    public var isTracking = false
    public var isBuffering: Bool = false

    public var player: AVPlayer
    public var onClose: VideoPlayerCloseAction?
    public var originalRate: Float = 1.0
    public var playbackSpeed: PlaybackSpeed = .x1_0 {
        didSet {
            originalRate = playbackSpeed.value
            player.defaultRate = playbackSpeed.value
            if isPlaying {
                player.rate = playbackSpeed.value
            }
        }
    }

#if os(iOS)
    public var isLooping: Bool = true
    var doubleTapCount: Int = 0
    private var doubleTapBaseTime: Double = 0
    private var doubleTapResetTask: Task<(), Never>?
    private var doubleTapDirection: SkipDirection?
    let rippleStore = RippleEffectStore()
    public var scrollView = UIScrollView()
    private var playerVC: AVPlayerViewController?
    public var isLongpress: Bool = false
#elseif os(macOS)
    /// When true, dragging on the player view moves the window.
    public var windowDraggable: Bool = false
    public var scrollView = PlayerScrollView()
    private var playerView: PlayerNSView?
#endif

    @ObservationIgnored private var cancellables = Set<AnyCancellable>()
    @ObservationIgnored private var currentItemObservation: NSKeyValueObservation?
    @ObservationIgnored private var itemStatusObservation: NSKeyValueObservation?
    @ObservationIgnored private var timeTask: Task<Void, any Error>? = nil

    // MARK: - Initializers
    public init(url: URL) {
        self.player = AVPlayer(url: url)
    }

    public init(player: AVPlayer) {
        self.player = player
    }

    // Replace the current player with a new instance while keeping the model.
    public func replacePlayer(with newPlayer: AVPlayer) {
        removePeriodicTimeObserver()
        cancellables.removeAll()
        player.pause()
        player = newPlayer
#if os(iOS)
        playerVC?.player = newPlayer
#elseif os(macOS)
        playerView?.setPlayer(newPlayer, videoGravity: .resizeAspect)
#endif
        newPlayer.defaultRate = playbackSpeed.value
        newPlayer.rate = playbackSpeed.value
        newPlayer.appliesMediaSelectionCriteriaAutomatically = false
        addObserver()
        if let item = newPlayer.currentItem {
            duration = CMTimeGetSeconds(item.duration)
        } else {
            duration = 0
        }
    }
    
    private func addObserver(){
        observePlayerStatus()
        observeSubtitleUpdates()
        addPeriodicTimeObserver()
    }
    
    public func replacePlayer(url: URL) {
        replacePlayer(with: AVPlayer(url: url))
    }

    private func observePlayerStatus() {
        player.publisher(for: \.timeControlStatus)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                switch status {
                case .playing:
                    if !self.isPlaying { self.isPlaying = true }
#if os(iOS)
                    if self.isLongpress {
                        let fastRate = min(self.originalRate * 2.0, 2.0)
                        if self.player.rate != fastRate {
                            self.player.rate = fastRate
                        }
                    }
#endif
                    if self.isBuffering { self.isBuffering = false }
                case .paused:
                    if self.isPlaying, !self.isTracking { self.isPlaying = false }
                    if self.isBuffering { self.isBuffering = false }
                case .waitingToPlayAtSpecifiedRate:
                    switch self.player.reasonForWaitingToPlay {
                    case .evaluatingBufferingRate, .toMinimizeStalls:
                        if !self.isBuffering { self.isBuffering = true }
                    default:
                        if self.isBuffering { self.isBuffering = false }
                    }
                @unknown default:
                    break
                }
            }
            .store(in: &cancellables)
    }

    private func observeSubtitleUpdates() {
        currentItemObservation?.invalidate()
        currentItemObservation = player.observe(\.currentItem, options: [.new, .initial]) { [weak self] player, _ in
            guard let self else { return }
            let currentItem = player.currentItem
            Task { @MainActor [weak self] in
                guard let self else { return }
                self.itemStatusObservation?.invalidate()
                if let item = currentItem {
                    self.itemStatusObservation = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
                        guard let self else { return }
                        if item.status == .readyToPlay {
                            Task { await self.loadSubtitleOptions() }
                        }
                    }
                }
            }
        }
    }

#if os(iOS)
    // MARK: - iOS Setup
    func setupPlayer() -> AVPlayerViewController {
        let vc = AVPlayerViewController()
        self.playerVC = vc
        let player = self.player
        vc.player = player
        player.appliesMediaSelectionCriteriaAutomatically = false
        addObserver()
        return vc
    }
#elseif os(macOS)
    // MARK: - macOS Setup
    func setupPlayerView() -> PlayerNSView {
        let view = PlayerNSView()
        view.model = self
        view.isWindowDraggable = windowDraggable
        self.playerView = view

        view.setPlayer(player, videoGravity: .resizeAspect)
        addObserver()

        if let item = player.currentItem {
            duration = CMTimeGetSeconds(item.duration)
        }
        return view
    }
#endif

    // MARK: - Time Observation
    private func addPeriodicTimeObserver(){
        let stream = player.periodicTimeStream(forInterval: CMTime(value: 1, timescale: 30),queue: .main)
        timeTask = Task{ [weak self] in
            for await time in stream{
                guard let self else { return }
                currentTime = CMTimeGetSeconds(time)
                if let item = player.currentItem {
                    let total = CMTimeGetSeconds(item.duration)
                    if total.isFinite { duration = total }
                }
                if !self.isTracking {
                    let ratio = (self.duration > 0) ? self.currentTime / self.duration : 0
#if os(macOS)
                    self.slider.doubleValue = ratio
#else
                    self.slider.value = Float(ratio)
#endif
                }
            }
        }
    }

    private func removePeriodicTimeObserver() {
        timeTask?.cancel()
    }

    // MARK: - Playback Controls
    func play() {
        if duration > 0 && (currentTime >= duration || (duration - currentTime) < 0.1) {
            seek(to: 0)
        }
        player.play()
        player.rate = playbackSpeed.value
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
        Task{
            let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            let shouldResume = isPlaying
            if await player.seek(to: time) {
                if shouldResume {
                    player.play()
                    player.rate = playbackSpeed.value
                }
            }
        }
    }

    public func seekPrecisely(to seconds: Double) {
        Task{
            let cm = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
            let shouldResume = isPlaying
            let result = await player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
            if result, shouldResume {
                player.play()
                player.rate = playbackSpeed.value
            }
            self.currentTime = seconds
        }
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

#if os(iOS)
    // MARK: - Gesture Support (iOS)
    @objc func handleDoubleTap(_ recognizer: UITapGestureRecognizer) {
        let location = recognizer.location(in: recognizer.view)
        guard let view = recognizer.view else { return }
        let viewWidth = view.bounds.width
        let tapX = location.x
        let current = currentTime
        let newDirection: SkipDirection = (tapX < viewWidth / 2) ? .backward : .forward

        if doubleTapDirection != newDirection {
            doubleTapCount = 0
            doubleTapBaseTime = current
            doubleTapDirection = newDirection
        }

        if doubleTapDirection == nil {
            doubleTapDirection = newDirection
            doubleTapBaseTime = current
        }

        doubleTapCount += 1
        let skipSeconds = Double(10 * doubleTapCount)
        let targetTime: Double
        switch doubleTapDirection {
        case .backward:
            targetTime = max(doubleTapBaseTime - skipSeconds, 0)
        case .forward:
            targetTime = min(doubleTapBaseTime + skipSeconds, duration)
        case .none:
            return
        }

        let labelSeconds = targetTime > .zero ? Int(skipSeconds) : .zero
        rippleStore.addRipple(at: location, duration: labelSeconds)
        seek(to: targetTime)

        doubleTapResetTask?.cancel()
        doubleTapResetTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled, let self else { return }
            self.doubleTapCount = 0
            self.doubleTapBaseTime = 0
            self.doubleTapDirection = nil
        }
    }

#endif

    // MARK: - Subtitle Support
    private var subtitleGroup: AVMediaSelectionGroup?
    public var subtitleOptions: [AVMediaSelectionOption] = []
    public var selectedSubtitle: AVMediaSelectionOption? {
        didSet { Task { await applySelectedSubtitle() } }
    }
}

#if os(iOS)
extension UIView {
    func setAnchorPoint(anchorPointInContainerView: CGPoint, forView view: UIView) {
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


extension PDPlayerModel {
    public func loadSubtitleOptions() async {
        guard let item = player.currentItem else { return }
        do {
            guard let group = try await item.asset.loadMediaSelectionGroup(for: .legible) else {
                self.subtitleGroup = nil
                self.subtitleOptions = []
                self.selectedSubtitle = nil
                return
            }
            self.subtitleGroup = group
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

public extension AVPlayer {
    func periodicTimeStream(
        forInterval interval: CMTime,
        queue: DispatchQueue
    ) -> AsyncStream<CMTime> {
        AsyncStream { continuation in
            let rawToken = addPeriodicTimeObserver(
                forInterval: interval,
                queue: queue
            ) { time in
                continuation.yield(time)
            }
            
            struct TokenBox: @unchecked Sendable {
                let token: Any
            }
            let box = TokenBox(token: rawToken)
            
            continuation.onTermination = { _ in
                self.removeTimeObserver(box.token)
            }
        }
    }
}
