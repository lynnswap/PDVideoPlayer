import AVFoundation
import Testing
@testable import PDVideoPlayer

@MainActor
@Test func playbackSpeedUpdatesPlayerRates() {
    let player = AVPlayer()
    let model = PlayerViewModel(player: player)

    model.isPlaying = true
    model.playbackSpeed = .x1_5

    #expect(model.originalRate == 1.5)
    #expect(player.defaultRate == 1.5)
    #expect(player.rate == 1.5)
}

@MainActor
@Test func playbackSpeedDoesNotChangeRateWhenPaused() {
    let player = AVPlayer()
    let model = PlayerViewModel(player: player)

    model.isPlaying = false
    player.rate = 0
    model.playbackSpeed = .x1_5

    #expect(model.originalRate == 1.5)
    #expect(player.defaultRate == 1.5)
    #expect(player.rate == 0)
}

@MainActor
@Test func cycleForwardAndRewindRatesUpdatePlayerState() {
    let player = AVPlayer()
    let model = PlayerViewModel(player: player)

    model.cycleForwardRate()
    #expect(model.isPlaying == true)
    #expect(player.rate == 2)

    model.cycleForwardRate()
    #expect(player.rate == 4)

    model.cycleRewindRate()
    #expect(player.rate == -2)
}

@MainActor
@Test func replacePlayerAppliesPlaybackSpeed() {
    let model = PlayerViewModel(player: AVPlayer())
    model.playbackSpeed = .x1_5

    let newPlayer = AVPlayer()
    model.replacePlayer(with: newPlayer)

    #expect(model.player === newPlayer)
    #expect(newPlayer.defaultRate == 1.5)
    #expect(newPlayer.rate == 1.5)
}

@MainActor
@Test func viewModelMapsPlayingAndPausedStatus() async throws {
    let observer = TestPlayerEngineObserver()
    let model = PlayerViewModel(player: AVPlayer(), observer: observer)
    model.startObserving()

    observer.statusContinuation?.yield(.playing)
    let didPlay = await waitUntil { model.isPlaying }
    #expect(didPlay == true)

    observer.statusContinuation?.yield(.paused)
    let didPause = await waitUntil { model.isPlaying == false }
    #expect(didPause == true)
}

@MainActor
@Test func viewModelMapsBufferingFromWaitingReason() async throws {
    let observer = TestPlayerEngineObserver()
    let model = PlayerViewModel(player: AVPlayer(), observer: observer)
    model.startObserving()

    observer.waitingReason = .toMinimizeStalls
    observer.statusContinuation?.yield(.waitingToPlayAtSpecifiedRate)
    let didBuffer = await waitUntil { model.isBuffering }
    #expect(didBuffer == true)

    observer.waitingReason = nil
    observer.statusContinuation?.yield(.waitingToPlayAtSpecifiedRate)
    let didClear = await waitUntil { model.isBuffering == false }
    #expect(didClear == true)
}

@MainActor
@Test func bufferingIndicatorShowsAfterDelay() async throws {
    let model = PlayerViewModel(player: AVPlayer())

    model.isBuffering = true
    #expect(model.showBufferingIndicator == false)

    let didShow = await waitUntil(timeout: .seconds(1)) { model.showBufferingIndicator }
    #expect(didShow == true)

    model.isBuffering = false
    #expect(model.showBufferingIndicator == false)
}

@MainActor
@Test func bufferingIndicatorDoesNotShowWhenBufferingStopsEarly() async throws {
    let model = PlayerViewModel(player: AVPlayer())

    model.isBuffering = true
    try await Task.sleep(for: .milliseconds(100))
    model.isBuffering = false

    let didShow = await waitUntil(timeout: .milliseconds(400)) { model.showBufferingIndicator }
    #expect(didShow == false)
}

@MainActor
@Test func bundledPreviewVideoLoadsReadyToPlay() async throws {
    let url = try previewVideoURL()
    let item = AVPlayerItem(url: url)
    let player = AVPlayer()
    player.replaceCurrentItem(with: item)

    let status = await waitForReady(item)
    #expect(status == .readyToPlay)
    #expect(item.duration.seconds.isFinite == true)
    #expect(item.duration.seconds > 0)
}

@MainActor
@Test func playbackAdvancesTimeForBundledVideo() async throws {
    let url = try previewVideoURL()
    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.isMuted = true
    player.automaticallyWaitsToMinimizeStalling = false

    let status = await waitForReady(item)
    #expect(status == .readyToPlay)

    player.play()
    defer { player.pause() }

    let advanced = await waitForPlaybackProgress(player: player)
    #expect(advanced == true)
}

@MainActor
@Test func playbackPauseStopsAdvancingTimeForBundledVideo() async throws {
    let url = try previewVideoURL()
    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.isMuted = true
    player.automaticallyWaitsToMinimizeStalling = false

    let status = await waitForReady(item)
    #expect(status == .readyToPlay)

    player.play()
    let advanced = await waitForPlaybackProgress(player: player)
    #expect(advanced == true)

    player.pause()
    let pausedAt = player.currentTime().seconds
    try await Task.sleep(for: .milliseconds(300))

    let drift = player.currentTime().seconds - pausedAt
    #expect(drift < 0.15)
}

@MainActor
@Test func seekThenPlayAdvancesFromSeekTimeForBundledVideo() async throws {
    let url = try previewVideoURL()
    let item = AVPlayerItem(url: url)
    let player = AVPlayer(playerItem: item)
    player.isMuted = true
    player.automaticallyWaitsToMinimizeStalling = false

    let status = await waitForReady(item)
    #expect(status == .readyToPlay)

    player.pause()
    let target = resolvedSeekTime(for: item)
    let didSeek = await seekPlayer(player, to: target)
    #expect(didSeek == true)
    let didSnap = await waitUntil(timeout: .seconds(1)) {
        abs(player.currentTime().seconds - target) < 0.3
    }
    #expect(didSnap == true)

    player.play()
    let advanced = await waitForPlaybackProgress(player: player)
    #expect(advanced == true)
    #expect(player.currentTime().seconds >= target)
}

@MainActor
@Test func seekPreciselyUpdatesCurrentTime() {
    let model = PlayerViewModel(player: AVPlayer())

    model.seekPrecisely(to: 12.3)
    #expect(model.currentTime == 12.3)
}

#if os(iOS)
@MainActor
@Test func beginAndEndLongPressAdjustsRate() {
    let player = AVPlayer()
    let model = PlayerViewModel(player: player)

    model.isPlaying = true
    player.rate = 1.25

    let didBegin = model.beginLongPress()
    #expect(didBegin == true)
    #expect(model.isLongpress == true)
    #expect(model.originalRate == 1.25)
    #expect(player.rate == 2.0)

    model.endLongPress()
    #expect(model.isLongpress == false)
    #expect(player.rate == 1.25)
}

@MainActor
@Test func beginLongPressWhenPausedDoesNothing() {
    let player = AVPlayer()
    let model = PlayerViewModel(player: player)

    model.isPlaying = false
    player.rate = 1.0

    let didBegin = model.beginLongPress()
    #expect(didBegin == false)
    #expect(model.isLongpress == false)
    #expect(player.rate == 1.0)
}

@MainActor
@Test func doubleTapAccumulatesSkipSecondsPerDirection() {
    let model = PlayerViewModel(player: AVPlayer())
    model.duration = 100
    model.currentTime = 50
    model.rippleStore.viewSize = CGSize(width: 100, height: 100)

    model.handleDoubleTap(at: CGPoint(x: 10, y: 50), viewWidth: 100)
    #expect(model.doubleTapCount == 1)
    #expect(model.rippleStore.latestItem?.skipDuration == 10)

    model.handleDoubleTap(at: CGPoint(x: 10, y: 50), viewWidth: 100)
    #expect(model.doubleTapCount == 2)
    #expect(model.rippleStore.latestItem?.skipDuration == 20)
}

@MainActor
@Test func doubleTapResetsCountWhenDirectionChanges() {
    let model = PlayerViewModel(player: AVPlayer())
    model.duration = 100
    model.currentTime = 50
    model.rippleStore.viewSize = CGSize(width: 100, height: 100)

    model.handleDoubleTap(at: CGPoint(x: 10, y: 50), viewWidth: 100)
    #expect(model.doubleTapCount == 1)

    model.handleDoubleTap(at: CGPoint(x: 90, y: 50), viewWidth: 100)
    #expect(model.doubleTapCount == 1)
    #expect(model.rippleStore.latestItem?.skipDuration == 10)
}

@MainActor
@Test func doubleTapResetsAfterDelay() async throws {
    let model = PlayerViewModel(player: AVPlayer())
    model.duration = 100
    model.currentTime = 50
    model.rippleStore.viewSize = CGSize(width: 100, height: 100)

    model.handleDoubleTap(at: CGPoint(x: 10, y: 50), viewWidth: 100)
    #expect(model.doubleTapCount == 1)

    let didReset = await waitUntil(timeout: .seconds(2)) { model.doubleTapCount == 0 }
    #expect(didReset == true)
}
#endif

@MainActor
@Test func playerEngineEmitsInitialAndStreamingTime() async throws {
    let observer = TestPlayerEngineObserver()
    observer.initialTime = (1.5, 10.0)
    let engine = PlayerEngine(player: AVPlayer(), observer: observer)

    var timeEvents: [(Double, Double)] = []
    let stream = engine.startObserving()
    let task = Task {
        for await event in stream {
            if case .time(let time, let duration) = event {
                timeEvents.append((time, duration))
            }
        }
    }
    defer {
        engine.stopObserving()
        task.cancel()
    }

    let didSeed = await waitUntil(timeout: .milliseconds(200)) { timeEvents.count == 1 }
    #expect(didSeed == true)

    #expect(timeEvents.count == 1)
    #expect(timeEvents.first?.0 == 1.5)
    #expect(timeEvents.first?.1 == 10.0)

    observer.timeContinuation?.yield(CMTime(seconds: 2, preferredTimescale: 1))
    let didUpdate = await waitUntil(timeout: .milliseconds(200)) { timeEvents.count > 1 }
    #expect(didUpdate == true)

    #expect(timeEvents.last?.0 == 2.0)
    #expect(timeEvents.last?.1 == 0.0)
}

@MainActor
@Test func playerEngineEmitsStatusUpdates() async throws {
    let observer = TestPlayerEngineObserver()
    let engine = PlayerEngine(player: AVPlayer(), observer: observer)

    var statusEvents: [AVPlayer.TimeControlStatus] = []
    let stream = engine.startObserving()
    let task = Task {
        for await event in stream {
            if case .status(let status, _) = event {
                statusEvents.append(status)
            }
        }
    }
    defer {
        engine.stopObserving()
        task.cancel()
    }

    observer.statusContinuation?.yield(.paused)
    let didReceive = await waitUntil(timeout: .milliseconds(200)) { statusEvents == [.paused] }
    #expect(didReceive == true)

    #expect(statusEvents == [.paused])
}

@MainActor
@Test func playerEngineEmitsItemReady() async throws {
    let observer = TestPlayerEngineObserver()
    let engine = PlayerEngine(player: AVPlayer(), observer: observer)

    var readyCount = 0
    let stream = engine.startObserving()
    let task = Task {
        for await event in stream {
            if case .itemReady = event {
                readyCount += 1
            }
        }
    }
    defer {
        engine.stopObserving()
        task.cancel()
    }

    let item = AVPlayerItem(asset: AVMutableComposition())
    engine.player.replaceCurrentItem(with: item)
    observer.currentItemContinuation?.yield(())
    let didSubscribe = await waitUntil(timeout: .milliseconds(200)) {
        observer.didRequestItemStatusStream
    }
    #expect(didSubscribe == true)
    observer.itemStatusContinuation?.yield(.readyToPlay)
    let didReady = await waitUntil(timeout: .milliseconds(200)) { readyCount == 1 }
    #expect(didReady == true)

    #expect(readyCount == 1)
}

@MainActor
@Test func playerEngineStopsObserving() async throws {
    let observer = TestPlayerEngineObserver()
    let engine = PlayerEngine(player: AVPlayer(), observer: observer)

    var statusEvents: [AVPlayer.TimeControlStatus] = []
    let stream = engine.startObserving()
    let task = Task {
        for await event in stream {
            if case .status(let status, _) = event {
                statusEvents.append(status)
            }
        }
    }
    defer { task.cancel() }

    engine.stopObserving()
    observer.statusContinuation?.yield(.paused)
    let didReceive = await waitUntil(timeout: .milliseconds(200)) { !statusEvents.isEmpty }
    #expect(didReceive == false)

    #expect(statusEvents.isEmpty)
}

@MainActor
@Test func playerEngineStopsTimeUpdatesAfterStopObserving() async throws {
    let observer = TestPlayerEngineObserver()
    let engine = PlayerEngine(player: AVPlayer(), observer: observer)

    var timeEvents: [(Double, Double)] = []
    let stream = engine.startObserving()
    let task = Task {
        for await event in stream {
            if case .time(let time, let duration) = event {
                timeEvents.append((time, duration))
            }
        }
    }
    defer {
        task.cancel()
    }

    let didSeed = await waitUntil(timeout: .milliseconds(200)) { timeEvents.count == 1 }
    #expect(didSeed == true)

    #expect(timeEvents.count == 1)

    engine.stopObserving()
    observer.timeContinuation?.yield(CMTime(seconds: 3, preferredTimescale: 1))
    let didReceive = await waitUntil(timeout: .milliseconds(200)) { timeEvents.count > 1 }
    #expect(didReceive == false)

    #expect(timeEvents.count == 1)
}

@MainActor
@Test func playerEngineEmitsItemFailedAndContinues() async throws {
    let observer = TestPlayerEngineObserver()
    let engine = PlayerEngine(player: AVPlayer(), observer: observer)

    var failedCount = 0
    var readyCount = 0
    let stream = engine.startObserving()
    let task = Task {
        for await event in stream {
            switch event {
            case .itemFailed:
                failedCount += 1
            case .itemReady:
                readyCount += 1
            default:
                break
            }
        }
    }
    defer {
        engine.stopObserving()
        task.cancel()
    }

    let item = AVPlayerItem(asset: AVMutableComposition())
    engine.player.replaceCurrentItem(with: item)
    observer.currentItemContinuation?.yield(())
    let didSubscribe = await waitUntil(timeout: .milliseconds(200)) {
        observer.didRequestItemStatusStream
    }
    #expect(didSubscribe == true)

    observer.itemStatusContinuation?.yield(.failed)
    let didFail = await waitUntil(timeout: .milliseconds(200)) { failedCount == 1 }
    #expect(didFail == true)

    observer.didRequestItemStatusStream = false
    let nextItem = AVPlayerItem(asset: AVMutableComposition())
    engine.player.replaceCurrentItem(with: nextItem)
    observer.currentItemContinuation?.yield(())
    let didResubscribe = await waitUntil(timeout: .milliseconds(200)) {
        observer.didRequestItemStatusStream
    }
    #expect(didResubscribe == true)

    observer.itemStatusContinuation?.yield(.readyToPlay)
    let didReady = await waitUntil(timeout: .milliseconds(200)) { readyCount == 1 }
    #expect(didReady == true)

    #expect(failedCount == 1)
    #expect(readyCount == 1)
}

final class TestPlayerEngineObserver: PlayerEngineObserving {
    var initialTime: (Double, Double) = (0, 0)
    var waitingReason: AVPlayer.WaitingReason?
    var didRequestItemStatusStream = false
    var timeContinuation: AsyncStream<CMTime>.Continuation?
    var statusContinuation: AsyncStream<AVPlayer.TimeControlStatus>.Continuation?
    var currentItemContinuation: AsyncStream<Void>.Continuation?
    var itemStatusContinuation: AsyncStream<AVPlayerItem.Status>.Continuation?

    @MainActor func initialTime(for player: AVPlayer) -> (Double, Double) { initialTime }

    @MainActor func timeStream(for player: AVPlayer) -> AnyAsyncSequence<CMTime> {
        AnyAsyncSequence(AsyncStream { continuation in
            timeContinuation = continuation
        })
    }

    @MainActor func timeControlStatusStream(for player: AVPlayer) -> AnyAsyncSequence<AVPlayer.TimeControlStatus> {
        AnyAsyncSequence(AsyncStream { continuation in
            statusContinuation = continuation
        })
    }

    @MainActor func currentItemStream(for player: AVPlayer) -> AnyAsyncSequence<Void> {
        AnyAsyncSequence(AsyncStream { continuation in
            currentItemContinuation = continuation
        })
    }

    @MainActor func itemStatusStream(for item: AVPlayerItem) -> AnyAsyncSequence<AVPlayerItem.Status> {
        didRequestItemStatusStream = true
        return AnyAsyncSequence(AsyncStream { continuation in
            itemStatusContinuation = continuation
        })
    }

    @MainActor func waitingReason(for player: AVPlayer) -> AVPlayer.WaitingReason? {
        waitingReason
    }
}

private enum TestResourceError: Error {
    case missingPreview
}

private func previewVideoURL() throws -> URL {
    guard let url = Bundle.module.url(forResource: "preview", withExtension: "mov") else {
        throw TestResourceError.missingPreview
    }
    return url
}

@MainActor
private func waitForReady(_ item: AVPlayerItem, timeout: Duration = .seconds(3)) async -> AVPlayerItem.Status {
    _ = await waitUntil(timeout: timeout, poll: .milliseconds(50)) {
        item.status != .unknown
    }

    return item.status
}

@MainActor
private func waitForPlaybackProgress(
    player: AVPlayer,
    minimumAdvance: Double = 0.2,
    timeout: Duration = .seconds(2)
) async -> Bool {
    let startTime = player.currentTime().seconds

    return await waitUntil(timeout: timeout, poll: .milliseconds(20)) {
        player.currentTime().seconds >= startTime + minimumAdvance
    }
}

@MainActor
private func seekPlayer(_ player: AVPlayer, to seconds: Double) async -> Bool {
    let time = CMTime(seconds: seconds, preferredTimescale: 600)
    return await withCheckedContinuation { continuation in
        player.seek(to: time, toleranceBefore: .zero, toleranceAfter: .zero) { finished in
            continuation.resume(returning: finished)
        }
    }
}

private func resolvedSeekTime(for item: AVPlayerItem) -> Double {
    let duration = item.duration.seconds
    if duration.isFinite {
        if duration > 0.2 {
            return min(1.0, duration - 0.1)
        }
        if duration > 0 {
            return duration / 2
        }
    }
    return 1.0
}

@MainActor
private func waitUntil(
    timeout: Duration = .seconds(2),
    poll: Duration = .milliseconds(20),
    condition: @escaping @MainActor () -> Bool
) async -> Bool {
    let clock = ContinuousClock()
    let deadline = clock.now.advanced(by: timeout)

    while clock.now < deadline {
        if condition() { return true }
        await Task.yield()
        try? await Task.sleep(for: poll)
    }

    return condition()
}
