import Foundation
import AVFoundation

enum PlayerEngineEvent: Sendable {
    case time(current: Double, duration: Double)
    case status(AVPlayer.TimeControlStatus, AVPlayer.WaitingReason?)
    case itemReady
    case itemFailed(description: String?)
}

@MainActor
final class PlayerEngine {
    private(set) var player: AVPlayer

    private var timeTask: Task<Void, Never>?
    private var statusTask: Task<Void, Never>?
    private var currentItemTask: Task<Void, Never>?
    private var eventBroadcaster = EventBroadcaster<PlayerEngineEvent>()
    private let observer: PlayerEngineObserving

    init(player: AVPlayer, observer: PlayerEngineObserving = PlayerEngineObserver()) {
        self.player = player
        self.observer = observer
        eventBroadcaster.onFirstSubscriber = { [weak self] in
            self?.startObservationTasks()
        }
        eventBroadcaster.onLastSubscriber = { [weak self] in
            self?.cancelObservationTasks()
        }
    }

    func replacePlayer(with newPlayer: AVPlayer) {
        player.pause()
        stopObserving()
        player = newPlayer
    }

    func startObserving() -> PlayerEventStream {
        player.appliesMediaSelectionCriteriaAutomatically = false

        let (initialTime, initialDuration) = observer.initialTime(for: player)
        return eventBroadcaster.makeStream { continuation in
            continuation.yield(.time(current: initialTime.isFinite ? initialTime : 0, duration: initialDuration))
            continuation.yield(.status(self.player.timeControlStatus, self.observer.waitingReason(for: self.player)))
        }
    }

    func stopObserving() {
        cancelObservationTasks()
        eventBroadcaster.finishAll()
    }

    private func cancelObservationTasks() {
        timeTask?.cancel()
        timeTask = nil
        statusTask?.cancel()
        statusTask = nil
        currentItemTask?.cancel()
        currentItemTask = nil
    }

    private func startObservationTasks() {
        timeTask?.cancel()
        statusTask?.cancel()
        currentItemTask?.cancel()

        let timeStream = observer.timeStream(for: player)
        let statusStream = observer.timeControlStatusStream(for: player)
        let itemStream = observer.currentItemStream(for: player)

        timeTask = Task { @MainActor [weak self] in
            await self?.observeTime(stream: timeStream)
        }

        statusTask = Task { @MainActor [weak self] in
            await self?.observeStatus(stream: statusStream)
        }

        currentItemTask = Task { @MainActor [weak self] in
            await self?.observeCurrentItem(stream: itemStream)
        }
    }

    private func observeTime(stream: AnyAsyncSequence<CMTime>) async {
        let timeStream = stream
        do {
            for try await time in timeStream {
                guard !Task.isCancelled else { break }
                let current = CMTimeGetSeconds(time)
                let duration = currentDurationSeconds()
                yieldEvent(.time(current: current.isFinite ? current : 0, duration: duration))
            }
        } catch {
            return
        }
    }

    private func observeStatus(stream: AnyAsyncSequence<AVPlayer.TimeControlStatus>) async {
        let statusStream = stream
        do {
            for try await status in statusStream {
                guard !Task.isCancelled else { break }
                yieldEvent(.status(status, observer.waitingReason(for: player)))
            }
        } catch {
            return
        }
    }

    private func observeCurrentItem(stream: AnyAsyncSequence<Void>) async {
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
                    yieldEvent(.time(current: initialTime.isFinite ? initialTime : 0, duration: initialDuration))
                } else {
                    didReceiveInitialItem = true
                }

                guard let item = player.currentItem else { continue }
                itemTask = Task { @MainActor [weak self] in
                    await self?.observeItemStatus(for: item)
                }
            }
        } catch {
            return
        }
    }

    private func observeItemStatus(for item: AVPlayerItem) async {
        let statusStream = observer.itemStatusStream(for: item)
        do {
            for try await status in statusStream {
                guard !Task.isCancelled else { break }
                switch status {
                case .readyToPlay:
                    yieldEvent(.itemReady)
                case .failed:
                    yieldEvent(.itemFailed(description: item.error?.localizedDescription))
                default:
                    break
                }
            }
        } catch {
            return
        }
    }

    private func currentDurationSeconds() -> Double {
        guard let item = player.currentItem else { return 0 }
        let total = CMTimeGetSeconds(item.duration)
        return total.isFinite ? total : 0
    }

    private func yieldEvent(_ event: PlayerEngineEvent) {
        eventBroadcaster.broadcast(event)
    }

    isolated deinit {
        stopObserving()
    }
}

@MainActor
private final class EventBroadcaster<Event: Sendable> {
    typealias Stream = AsyncStream<Event>

    private var continuations: [UUID: Stream.Continuation] = [:]
    var onFirstSubscriber: () -> Void = {}
    var onLastSubscriber: () -> Void = {}

    func makeStream(onSubscribe: ((Stream.Continuation) -> Void)? = nil) -> Stream {
        Stream { [weak self] continuation in
            guard let self else {
                continuation.finish()
                return
            }

            let streamID = UUID()
            continuations[streamID] = continuation

            onSubscribe?(continuation)

            if continuations.count == 1 {
                onFirstSubscriber()
            }

            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.removeContinuation(id: streamID)
                }
            }
        }
    }

    func broadcast(_ event: Event) {
        guard !continuations.isEmpty else { return }
        for continuation in continuations.values {
            continuation.yield(event)
        }
    }

    func finishAll() {
        let activeContinuations = Array(continuations.values)
        continuations.removeAll()
        activeContinuations.forEach { $0.finish() }
    }

    private func removeContinuation(id: UUID) {
        guard continuations.removeValue(forKey: id) != nil else { return }
        if continuations.isEmpty {
            onLastSubscriber()
        }
    }
}

typealias PlayerEventStream = AsyncStream<PlayerEngineEvent>

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
