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
    public private(set) var state: PlayerState
    @ObservationIgnored private var bufferingTask: Task<Void, any Error>?
    @ObservationIgnored private var observeTask: Task<Void, Never>?

    public var player: AVPlayer { engine.player }
    public var onClose: VideoPlayerCloseAction?

    public var isPlaying: Bool {
        get { state.isPlaying }
        set { updateState { $0.isPlaying = newValue } }
    }

    public var currentTime: Double {
        get { state.currentTime }
        set { updateState { $0.currentTime = newValue } }
    }

    public var duration: Double {
        get { state.duration }
        set { updateState { $0.duration = newValue } }
    }

    public var isTracking: Bool {
        get { state.isTracking }
        set { updateState { $0.isTracking = newValue } }
    }

    /// True while trackpad scrubbing is active (macOS overlay).
    public var isScrubbing: Bool {
        get { state.isScrubbing }
        set { updateState { $0.isScrubbing = newValue } }
    }

    public var isBuffering: Bool {
        get { state.isBuffering }
        set { setBuffering(newValue) }
    }

    public var showBufferingIndicator: Bool { state.showBufferingIndicator }

    public var originalRate: Float { state.originalRate }

    public var playbackSpeed: PlaybackSpeed {
        get { state.playbackSpeed }
        set { setPlaybackSpeed(newValue) }
    }

#if os(iOS)
    public var isLooping: Bool {
        get { state.isLooping }
        set { updateState { $0.isLooping = newValue } }
    }

    public var doubleTapCount: Int { state.doubleTapCount }
    public var isLongpress: Bool { state.isLongpress }
    private var doubleTapResetTask: Task<Void, any Error>?
    let rippleStore = RippleEffectStore()
#elseif os(macOS)
    /// When true, dragging on the player view moves the window.
    public var windowDraggable: Bool {
        get { state.windowDraggable }
        set { updateState { $0.windowDraggable = newValue } }
    }
#endif

    @ObservationIgnored private let engine: PlayerEngine

    // MARK: - Initializers
    public init(url: URL) {
        let player = AVPlayer(url: url)
        self.engine = PlayerEngine(player: player)
        self.state = .default
    }

    public init(player: AVPlayer) {
        self.engine = PlayerEngine(player: player)
        self.state = .default
    }

    init(player: AVPlayer, observer: PlayerEngineObserving) {
        self.engine = PlayerEngine(player: player, observer: observer)
        self.state = .default
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
        newPlayer.defaultRate = state.playbackSpeed.value
        newPlayer.rate = state.playbackSpeed.value
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
                    updateState { state in
                        state.currentTime = current
                        state.duration = duration
                    }
                case .status(let status, let waitingReason):
                    switch status {
                    case .playing:
                        if !state.isPlaying { updateState { $0.isPlaying = true } }
#if os(iOS)
                        if state.isLongpress {
                            let fastRate = min(state.originalRate * 2.0, 2.0)
                            if player.rate != fastRate { player.rate = fastRate }
                        }
#endif
                        if state.isBuffering { setBuffering(false) }
                    case .paused:
                        if state.isPlaying, !state.isTracking { updateState { $0.isPlaying = false } }
                        if state.isBuffering { setBuffering(false) }
                    case .waitingToPlayAtSpecifiedRate:
                        switch waitingReason {
                        case .evaluatingBufferingRate, .toMinimizeStalls:
                            if !state.isBuffering { setBuffering(true) }
                        default:
                            if state.isBuffering { setBuffering(false) }
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
        player.rate = state.playbackSpeed.value
    }

    func pause() { player.pause() }

    public func togglePlay() {
        isPlaying ? pause() : play()
    }

    public func seekRatio(_ ratio: Double) {
        let target = state.duration * ratio
        seek(to: target)
    }

    public func seek(to seconds: Double) {
        let time = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: time)
    }

    public func seekPrecisely(to seconds: Double) {
        let cm = CMTime(seconds: seconds, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        player.seek(to: cm, toleranceBefore: .zero, toleranceAfter: .zero)
        updateState { $0.currentTime = seconds }
    }

    // MARK: - Keyboard Navigation Support
    func stepFrames(by count: Int) {
        pause()
        player.currentItem?.step(byCount: count)
        if let current = player.currentItem?.currentTime() {
            updateState { $0.currentTime = CMTimeGetSeconds(current) }
        }
    }

    private var rateIndex: Int = 0
    private let rateValues: [Float] = [1, 2, 4, 8, 16]
    private var isRewind: Bool = false

    func cycleForwardRate() {
        if isRewind { rateIndex = 0; isRewind = false }
        rateIndex = min(rateIndex + 1, rateValues.count - 1)
        player.rate = rateValues[rateIndex]
        updateState { $0.isPlaying = true }
    }

    func cycleRewindRate() {
        if !isRewind { rateIndex = 0; isRewind = true }
        rateIndex = min(rateIndex + 1, rateValues.count - 1)
        player.rate = -rateValues[rateIndex]
        updateState { $0.isPlaying = true }
    }

#if os(iOS)
    // MARK: - Gesture Support (iOS)
    func handleDoubleTap(at location: CGPoint, viewWidth: CGFloat) {
        guard viewWidth > 0 else { return }
        let tapX = location.x
        let current = state.currentTime
        let newDirection: SkipDirection = (tapX < viewWidth / 2) ? .backward : .forward

        if state.doubleTapDirection != newDirection {
            updateState {
                $0.doubleTapCount = 0
                $0.doubleTapBaseTime = current
                $0.doubleTapDirection = newDirection
            }
        }

        if state.doubleTapDirection == nil {
            updateState {
                $0.doubleTapDirection = newDirection
                $0.doubleTapBaseTime = current
            }
        }

        updateState { $0.doubleTapCount += 1 }
        let skipSeconds = Double(10 * state.doubleTapCount)
        let targetTime: Double
        switch state.doubleTapDirection {
        case .backward:
            targetTime = max(state.doubleTapBaseTime - skipSeconds, 0)
        case .forward:
            targetTime = min(state.doubleTapBaseTime + skipSeconds, state.duration)
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
            updateState {
                $0.doubleTapCount = 0
                $0.doubleTapBaseTime = 0
                $0.doubleTapDirection = nil
            }
        }
    }

    func beginLongPress() -> Bool {
        guard state.isPlaying else { return false }
        updateState { $0.originalRate = player.rate }
        let fastRate = min(state.originalRate * 2.0, 2.0)
        if player.rate != fastRate {
            player.rate = fastRate
        }
        updateState { $0.isLongpress = true }
        return true
    }

    func endLongPress() {
        guard state.isLongpress else { return }
        player.rate = state.originalRate
        updateState { $0.isLongpress = false }
    }

#endif

    // MARK: - Subtitle Support
    private var subtitleGroup: AVMediaSelectionGroup?
    public var subtitleOptions: [AVMediaSelectionOption] = []
    public var selectedSubtitle: AVMediaSelectionOption? {
        didSet { Task { await applySelectedSubtitle() } }
    }
}

private extension PlayerViewModel {
    func updateState(_ mutate: (inout PlayerState) -> Void) {
        var next = state
        mutate(&next)
        state = next
    }

    func setPlaybackSpeed(_ speed: PlaybackSpeed) {
        updateState {
            $0.playbackSpeed = speed
            $0.originalRate = speed.value
        }
        engine.player.defaultRate = speed.value
        if state.isPlaying {
            engine.player.rate = speed.value
        }
    }

    func setBuffering(_ buffering: Bool) {
        updateState { $0.isBuffering = buffering }
        if buffering {
            bufferingTask?.cancel()
            bufferingTask = Task {
                try await Task.sleep(for: .milliseconds(300))
                guard !Task.isCancelled else { return }
                updateState { $0.showBufferingIndicator = true }
            }
        } else {
            bufferingTask?.cancel()
            updateState { $0.showBufferingIndicator = false }
        }
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
