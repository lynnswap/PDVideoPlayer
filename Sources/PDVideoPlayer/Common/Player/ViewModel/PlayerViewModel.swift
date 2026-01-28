#if os(macOS)
import AppKit
#endif
import SwiftUI
@preconcurrency import AVFoundation

#if os(iOS)
enum SkipDirection {
    case backward
    case forward
}
#endif

@MainActor
@Observable
public final class PlayerViewModel {
    // MARK: - Common Properties
    public var isPlaying: Bool = false
    public var currentTime: Double = 0
    public var duration: Double = 0

    public var isTracking = false
    /// True while trackpad scrubbing is active (macOS overlay).
    public var isScrubbing = false
    public var isBuffering: Bool = false {
        didSet {
            if isBuffering {
                bufferingTask?.cancel()
                bufferingTask = Task {
                    try await Task.sleep(for: .milliseconds(300))
                    guard !Task.isCancelled else { return }
                    self.showBufferingIndicator = true
                }
            } else {
                bufferingTask?.cancel()
                showBufferingIndicator = false
            }
        }
    }
    public var showBufferingIndicator: Bool = false
    @ObservationIgnored private var bufferingTask: Task<Void, any Error>?
    @ObservationIgnored private var observeTask: Task<Void, Never>?

    public var player: AVPlayer { engine.player }
    public var onClose: VideoPlayerCloseAction?
    public private(set) var originalRate: Float = 1.0
    public var playbackSpeed: PlaybackSpeed = .x1_0 {
        didSet {
            originalRate = playbackSpeed.value
            engine.player.defaultRate = playbackSpeed.value
            if isPlaying {
                engine.player.rate = playbackSpeed.value
            }
        }
    }

#if os(iOS)
    public var isLooping: Bool = true
    var doubleTapCount: Int = 0
    private var doubleTapBaseTime: Double = 0
    private var doubleTapResetTask: Task<Void, any Error>?
    private var doubleTapDirection: SkipDirection?
    let rippleStore = RippleEffectStore()
    public private(set) var isLongpress: Bool = false
#elseif os(macOS)
    /// When true, dragging on the player view moves the window.
    public var windowDraggable: Bool = false
#endif

    @ObservationIgnored private let engine: PlayerEngine

    // MARK: - Initializers
    public init(url: URL) {
        let player = AVPlayer(url: url)
        self.engine = PlayerEngine(player: player)
    }

    public init(player: AVPlayer) {
        self.engine = PlayerEngine(player: player)
    }

    init(player: AVPlayer, observer: PlayerEngineObserving) {
        self.engine = PlayerEngine(player: player, observer: observer)
    }

    isolated deinit {
        bufferingTask?.cancel()
        observeTask?.cancel()
#if os(iOS)
        doubleTapResetTask?.cancel()
#endif
    }

    // Replace the current player with a new instance while keeping the model.
    public func replacePlayer(with newPlayer: AVPlayer) {
        engine.replacePlayer(with: newPlayer)
        newPlayer.defaultRate = playbackSpeed.value
        newPlayer.rate = playbackSpeed.value
        startObserving()
    }
    
    func startObserving() {
        observeTask?.cancel()
        let stream = engine.startObserving()
        observeTask = Task { @MainActor [weak self] in
            guard let self else { return }
            for await event in stream {
                switch event {
                case .time(let current, let duration):
                    currentTime = current
                    self.duration = duration
                case .status(let status, let waitingReason):
                    switch status {
                    case .playing:
                        if !isPlaying { isPlaying = true }
#if os(iOS)
                        if isLongpress {
                            let fastRate = min(originalRate * 2.0, 2.0)
                            if player.rate != fastRate {
                                player.rate = fastRate
                            }
                        }
#endif
                        if isBuffering { isBuffering = false }
                    case .paused:
                        if isPlaying, !isTracking { isPlaying = false }
                        if isBuffering { isBuffering = false }
                    case .waitingToPlayAtSpecifiedRate:
                        switch waitingReason {
                        case .evaluatingBufferingRate, .toMinimizeStalls:
                            if !isBuffering { isBuffering = true }
                        default:
                            if isBuffering { isBuffering = false }
                        }
                    @unknown default:
                        break
                    }
                case .itemReady:
                    Task { await loadSubtitleOptions() }
                }
            }
        }
    }
    
    public func replacePlayer(url: URL) {
        replacePlayer(with: AVPlayer(url: url))
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

#if os(iOS)
    // MARK: - Gesture Support (iOS)
    func handleDoubleTap(at location: CGPoint, viewWidth: CGFloat) {
        guard viewWidth > 0 else { return }
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
        doubleTapResetTask = Task {
            try await Task.sleep(for: .seconds(1.2))
            guard !Task.isCancelled else { return }
            self.doubleTapCount = 0
            self.doubleTapBaseTime = 0
            self.doubleTapDirection = nil
        }
    }

    func beginLongPress() -> Bool {
        guard isPlaying else { return false }
        originalRate = player.rate
        let fastRate = min(originalRate * 2.0, 2.0)
        if player.rate != fastRate {
            player.rate = fastRate
        }
        isLongpress = true
        return true
    }

    func endLongPress() {
        guard isLongpress else { return }
        player.rate = originalRate
        isLongpress = false
    }

#endif

    // MARK: - Subtitle Support
    private var subtitleGroup: AVMediaSelectionGroup?
    public var subtitleOptions: [AVMediaSelectionOption] = []
    public var selectedSubtitle: AVMediaSelectionOption? {
        didSet { Task { await applySelectedSubtitle() } }
    }
}

extension PlayerViewModel {
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
