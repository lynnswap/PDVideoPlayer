import Foundation
import AVFoundation

@MainActor
final class PlayerEngine {
    enum Event {
        case time(current: Double, duration: Double)
        case status(AVPlayer.TimeControlStatus, AVPlayer.WaitingReason?)
        case itemReady
    }

    enum StreamError: Error {
        case itemFailed(underlying: Error?)
    }

    private(set) var player: AVPlayer

    private var timeTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?
    private var currentItemTask: Task<Void, Never>?
    private var eventContinuation: AsyncThrowingStream<Event, Error>.Continuation?
    private var currentStreamID: UUID?
    private let observer: PlayerEngineObserving

    init(player: AVPlayer, observer: PlayerEngineObserving = PlayerEngineObserver()) {
        self.player = player
        self.observer = observer
    }

    func replacePlayer(with newPlayer: AVPlayer) {
        player.pause()
        stopObserving()
        player = newPlayer
    }

    func startObserving() -> PlayerEventStream {
        stopObserving(finishStream: true)
        player.appliesMediaSelectionCriteriaAutomatically = false

        let streamID = UUID()
        currentStreamID = streamID
        let stream = AsyncThrowingStream<Event, Error> { continuation in
            eventContinuation = continuation
        }

        let (initialTime, initialDuration) = observer.initialTime(for: player)
        yieldEvent(.time(current: initialTime.isFinite ? initialTime : 0, duration: initialDuration), streamID: streamID)

        startObservationTasks(streamID: streamID)

        return PlayerEventStream(stream: stream) { [weak self] in
            Task { @MainActor [weak self] in
                self?.invalidateStreamIfCurrent(streamID: streamID)
            }
        }
    }

    func stopObserving() {
        stopObserving(finishStream: true)
    }

    private func stopObserving(finishStream: Bool) {
        cancelObservationTasks()
        if finishStream {
            eventContinuation?.finish()
        }
        eventContinuation = nil
        currentStreamID = nil
    }

    private func cancelObservationTasks() {
        timeTask?.cancel()
        timeTask = nil
        statusTask?.cancel()
        statusTask = nil
        currentItemTask?.cancel()
        currentItemTask = nil
    }

    private func invalidateStreamIfCurrent(streamID: UUID) {
        guard currentStreamID == streamID else { return }
        cancelObservationTasks()
        eventContinuation = nil
        currentStreamID = nil
    }

    private func startObservationTasks(streamID: UUID) {
        timeTask?.cancel()
        statusTask?.cancel()
        currentItemTask?.cancel()

        let timeStream = observer.timeStream(for: player)
        let statusStream = observer.timeControlStatusStream(for: player)
        let itemStream = observer.currentItemStream(for: player)

        timeTask = Task { @MainActor [weak self] in
            await self?.observeTime(stream: timeStream, streamID: streamID)
        }

        statusTask = Task { @MainActor [weak self] in
            await self?.observeStatus(stream: statusStream, streamID: streamID)
        }

        currentItemTask = Task { @MainActor [weak self] in
            await self?.observeCurrentItem(stream: itemStream, streamID: streamID)
        }
    }

    private func observeTime(stream: AnyAsyncSequence<CMTime>, streamID: UUID) async {
        let timeStream = stream
        do {
            for try await time in timeStream {
                guard !Task.isCancelled else { break }
                let current = CMTimeGetSeconds(time)
                let duration = currentDurationSeconds()
                yieldEvent(.time(current: current.isFinite ? current : 0, duration: duration), streamID: streamID)
            }
        } catch {
            return
        }
    }

    private func observeStatus(stream: AnyAsyncSequence<AVPlayer.TimeControlStatus>, streamID: UUID) async {
        let statusStream = stream
        do {
            for try await status in statusStream {
                guard !Task.isCancelled else { break }
                yieldEvent(.status(status, observer.waitingReason(for: player)), streamID: streamID)
            }
        } catch {
            return
        }
    }

    private func observeCurrentItem(stream: AnyAsyncSequence<Void>, streamID: UUID) async {
        let itemStream = stream
        var itemTask: Task<Void, Never>?
        var didReceiveInitialItem = false
        defer { itemTask?.cancel() }

        do {
            for try await _ in itemStream {
                guard !Task.isCancelled else { break }
                itemTask?.cancel()
                itemTask = nil

                if didReceiveInitialItem {
                    let (initialTime, initialDuration) = observer.initialTime(for: player)
                    yieldEvent(.time(current: initialTime.isFinite ? initialTime : 0, duration: initialDuration), streamID: streamID)
                } else {
                    didReceiveInitialItem = true
                }

                guard let item = player.currentItem else { continue }
                itemTask = Task { @MainActor [weak self] in
                    await self?.observeItemStatus(for: item, streamID: streamID)
                }
            }
        } catch {
            return
        }
    }

    private func observeItemStatus(for item: AVPlayerItem, streamID: UUID) async {
        let statusStream = observer.itemStatusStream(for: item)
        do {
            for try await status in statusStream {
                guard !Task.isCancelled else { break }
                switch status {
                case .readyToPlay:
                    yieldEvent(.itemReady, streamID: streamID)
                case .failed:
                    finishStream(throwing: StreamError.itemFailed(underlying: item.error), streamID: streamID)
                    return
                default:
                    break
                }
            }
        } catch {
            return
        }
    }

    private func finishStream(throwing error: Error, streamID: UUID) {
        guard currentStreamID == streamID else { return }
        cancelObservationTasks()
        eventContinuation?.finish(throwing: error)
        eventContinuation = nil
        currentStreamID = nil
    }

    private func currentDurationSeconds() -> Double {
        guard let item = player.currentItem else { return 0 }
        let total = CMTimeGetSeconds(item.duration)
        return total.isFinite ? total : 0
    }

    private func yieldEvent(_ event: Event, streamID: UUID) {
        guard currentStreamID == streamID else { return }
        eventContinuation?.yield(event)
    }

    isolated deinit {
        stopObserving()
    }
}

@MainActor
final class PlayerEventStream: AsyncSequence {
    typealias Element = PlayerEngine.Event
    typealias AsyncIterator = Iterator

    nonisolated let stream: AsyncThrowingStream<Element, Error>
    private let onTermination: @Sendable () -> Void

    init(
        stream: AsyncThrowingStream<Element, Error>,
        onTermination: @escaping @Sendable () -> Void
    ) {
        self.stream = stream
        self.onTermination = onTermination
    }

    nonisolated func makeAsyncIterator() -> Iterator {
        Iterator(
            iterator: stream.makeAsyncIterator(),
            onTermination: onTermination
        )
    }

    isolated deinit {
        onTermination()
    }

    final class Iterator: AsyncIteratorProtocol {
        private var iterator: AsyncThrowingStream<PlayerEngine.Event, Error>.AsyncIterator
        private var onTermination: (@Sendable () -> Void)?

        init(
            iterator: AsyncThrowingStream<PlayerEngine.Event, Error>.AsyncIterator,
            onTermination: @escaping @Sendable () -> Void
        ) {
            self.iterator = iterator
            self.onTermination = onTermination
        }

        func next() async throws -> PlayerEngine.Event? {
            var localIterator = iterator
            defer { iterator = localIterator }
            return try await localIterator.next()
        }

        deinit {
            onTermination?()
            onTermination = nil
        }
    }
}

struct AnyAsyncSequence<Element>: AsyncSequence {
    typealias AsyncIterator = AnyAsyncIterator<Element>

    private let _makeIterator: () -> AnyAsyncIterator<Element>

    init<S: AsyncSequence>(_ sequence: S) where S.Element == Element {
        _makeIterator = {
            var iterator = sequence.makeAsyncIterator()
            return AnyAsyncIterator {
                try await iterator.next()
            }
        }
    }

    func makeAsyncIterator() -> AnyAsyncIterator<Element> {
        _makeIterator()
    }
}

struct AnyAsyncIterator<Element>: AsyncIteratorProtocol {
    private let _next: () async throws -> Element?

    init(_ next: @escaping () async throws -> Element?) {
        _next = next
    }

    mutating func next() async throws -> Element? {
        try await _next()
    }
}

private final class KVOAsyncSequence<Object: NSObject, Value: Sendable>: AsyncSequence {
    typealias Element = Value

    private let stream: AsyncStream<Value>
    private let continuation: AsyncStream<Value>.Continuation
    private var observation: NSKeyValueObservation?

    init(
        object: Object,
        keyPath: KeyPath<Object, Value>,
        options: NSKeyValueObservingOptions = [.new, .initial],
        bufferingPolicy: AsyncStream<Value>.Continuation.BufferingPolicy = .bufferingNewest(1)
    ) {
        (stream, continuation) = AsyncStream.makeStream(bufferingPolicy: bufferingPolicy)
        let continuation = continuation
        observation = object.observe(keyPath, options: options) { _, change in
            guard let value = change.newValue else { return }
            continuation.yield(value)
        }
    }

    func makeAsyncIterator() -> AsyncStream<Value>.Iterator {
        stream.makeAsyncIterator()
    }

    deinit {
        observation?.invalidate()
        continuation.finish()
    }
}

private final class KVOChangeSignalSequence<Object: NSObject, Value>: AsyncSequence {
    typealias Element = Void

    private let stream: AsyncStream<Void>
    private let continuation: AsyncStream<Void>.Continuation
    private var observation: NSKeyValueObservation?

    init(
        object: Object,
        keyPath: KeyPath<Object, Value?>,
        options: NSKeyValueObservingOptions = [.new, .initial]
    ) {
        (stream, continuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(1))
        let continuation = continuation
        observation = object.observe(keyPath, options: options) { _, _ in
            continuation.yield(())
        }
    }

    func makeAsyncIterator() -> AsyncStream<Void>.Iterator {
        stream.makeAsyncIterator()
    }

    deinit {
        observation?.invalidate()
        continuation.finish()
    }
}

private final class PeriodicTimeSequence: AsyncSequence {
    typealias Element = CMTime

    private let stream: AsyncStream<CMTime>
    private let continuation: AsyncStream<CMTime>.Continuation
    private weak var player: AVPlayer?
    private var token: Any?

    init(
        player: AVPlayer,
        interval: CMTime,
        queue: DispatchQueue
    ) {
        self.player = player
        (stream, continuation) = AsyncStream.makeStream(bufferingPolicy: .bufferingNewest(1))
        let continuation = continuation
        token = player.addPeriodicTimeObserver(forInterval: interval, queue: queue) { time in
            continuation.yield(time)
        }
    }

    func makeAsyncIterator() -> AsyncStream<CMTime>.Iterator {
        stream.makeAsyncIterator()
    }

    deinit {
        continuation.finish()
        if let player, let token {
            player.removeTimeObserver(token)
        }
    }
}

protocol PlayerEngineObserving {
    @MainActor func initialTime(for player: AVPlayer) -> (Double, Double)
    @MainActor func timeStream(for player: AVPlayer) -> AnyAsyncSequence<CMTime>
    @MainActor func timeControlStatusStream(for player: AVPlayer) -> AnyAsyncSequence<AVPlayer.TimeControlStatus>
    @MainActor func currentItemStream(for player: AVPlayer) -> AnyAsyncSequence<Void>
    @MainActor func itemStatusStream(for item: AVPlayerItem) -> AnyAsyncSequence<AVPlayerItem.Status>
    @MainActor func waitingReason(for player: AVPlayer) -> AVPlayer.WaitingReason?
}

struct PlayerEngineObserver: PlayerEngineObserving {
    @MainActor func initialTime(for player: AVPlayer) -> (Double, Double) {
        let initialDuration = currentDurationSeconds(for: player)
        let initialTime = CMTimeGetSeconds(player.currentTime())
        return (initialTime.isFinite ? initialTime : 0, initialDuration)
    }

    @MainActor func timeStream(for player: AVPlayer) -> AnyAsyncSequence<CMTime> {
        AnyAsyncSequence(
            PeriodicTimeSequence(
                player: player,
                interval: CMTime(value: 1, timescale: 30),
                queue: .main
            )
        )
    }

    @MainActor func timeControlStatusStream(for player: AVPlayer) -> AnyAsyncSequence<AVPlayer.TimeControlStatus> {
        AnyAsyncSequence(KVOAsyncSequence(object: player, keyPath: \.timeControlStatus))
    }

    @MainActor func currentItemStream(for player: AVPlayer) -> AnyAsyncSequence<Void> {
        AnyAsyncSequence(KVOChangeSignalSequence(object: player, keyPath: \.currentItem))
    }

    @MainActor func itemStatusStream(for item: AVPlayerItem) -> AnyAsyncSequence<AVPlayerItem.Status> {
        AnyAsyncSequence(KVOAsyncSequence(object: item, keyPath: \.status, options: [.new, .initial]))
    }

    @MainActor func waitingReason(for player: AVPlayer) -> AVPlayer.WaitingReason? {
        player.reasonForWaitingToPlay
    }

    @MainActor
    private func currentDurationSeconds(for player: AVPlayer) -> Double {
        guard let item = player.currentItem else { return 0 }
        let total = CMTimeGetSeconds(item.duration)
        return total.isFinite ? total : 0
    }
}
