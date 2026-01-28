import Foundation
import AVFoundation
import Combine

@MainActor
final class PlayerEngine {
    enum Event {
        case time(current: Double, duration: Double)
        case status(AVPlayer.TimeControlStatus, AVPlayer.WaitingReason?)
        case itemReady
    }

    private(set) var player: AVPlayer

    private var cancellables = Set<AnyCancellable>()
    private var itemStatusCancellable: AnyCancellable?
    private var timeTask: Task<Void, Never>?
    private var eventContinuation: AsyncStream<Event>.Continuation?
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

    func startObserving() -> AsyncStream<Event> {
        stopObserving()
        player.appliesMediaSelectionCriteriaAutomatically = false

        let stream = AsyncStream<Event> { continuation in
            eventContinuation = continuation
            continuation.onTermination = { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.stopObserving()
                }
            }
        }

        let (initialTime, initialDuration) = observer.initialTime(for: player)
        yieldEvent(.time(current: initialTime.isFinite ? initialTime : 0, duration: initialDuration))

        observer.timeControlStatusPublisher(for: player)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] status in
                guard let self else { return }
                self.yieldEvent(.status(status, self.observer.waitingReason(for: self.player)))
            }
            .store(in: &cancellables)

        observer.currentItemPublisher(for: player)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] item in
                guard let self else { return }
                self.itemStatusCancellable?.cancel()
                self.itemStatusCancellable = nil
                guard let item else { return }
                self.itemStatusCancellable = self.observer.itemStatusPublisher(for: item)
                    .receive(on: DispatchQueue.main)
                    .sink { status in
                        if status == .readyToPlay {
                            self.yieldEvent(.itemReady)
                        }
                    }
            }
            .store(in: &cancellables)

        let timeStream = observer.timeStream(for: player)
        timeTask = Task { [weak self] in
            for await time in timeStream {
                guard let self else { return }
                if Task.isCancelled { break }
                let current = CMTimeGetSeconds(time)
                let duration = currentDurationSeconds()
                self.yieldEvent(.time(current: current.isFinite ? current : 0, duration: duration))
            }
        }

        return stream
    }

    func stopObserving() {
        timeTask?.cancel()
        timeTask = nil
        itemStatusCancellable?.cancel()
        itemStatusCancellable = nil
        cancellables.removeAll()
        eventContinuation?.finish()
        eventContinuation = nil
    }

    private func currentDurationSeconds() -> Double {
        guard let item = player.currentItem else { return 0 }
        let total = CMTimeGetSeconds(item.duration)
        return total.isFinite ? total : 0
    }

    private func yieldEvent(_ event: Event) {
        eventContinuation?.yield(event)
    }

    isolated deinit {
        stopObserving()
    }
}

protocol PlayerEngineObserving {
    func initialTime(for player: AVPlayer) -> (Double, Double)
    @MainActor func timeStream(for player: AVPlayer) -> AsyncStream<CMTime>
    func timeControlStatusPublisher(for player: AVPlayer) -> AnyPublisher<AVPlayer.TimeControlStatus, Never>
    func currentItemPublisher(for player: AVPlayer) -> AnyPublisher<AVPlayerItem?, Never>
    func itemStatusPublisher(for item: AVPlayerItem) -> AnyPublisher<AVPlayerItem.Status, Never>
    func waitingReason(for player: AVPlayer) -> AVPlayer.WaitingReason?
}

struct PlayerEngineObserver: PlayerEngineObserving {
    func initialTime(for player: AVPlayer) -> (Double, Double) {
        let initialDuration = currentDurationSeconds(for: player)
        let initialTime = CMTimeGetSeconds(player.currentTime())
        return (initialTime.isFinite ? initialTime : 0, initialDuration)
    }

    @MainActor func timeStream(for player: AVPlayer) -> AsyncStream<CMTime> {
        player.periodicTimeStream(
            forInterval: CMTime(value: 1, timescale: 30),
            queue: .main
        )
    }

    func timeControlStatusPublisher(for player: AVPlayer) -> AnyPublisher<AVPlayer.TimeControlStatus, Never> {
        player.publisher(for: \.timeControlStatus)
            .eraseToAnyPublisher()
    }

    func currentItemPublisher(for player: AVPlayer) -> AnyPublisher<AVPlayerItem?, Never> {
        player.publisher(for: \.currentItem, options: [.new, .initial])
            .eraseToAnyPublisher()
    }

    func itemStatusPublisher(for item: AVPlayerItem) -> AnyPublisher<AVPlayerItem.Status, Never> {
        item.publisher(for: \.status, options: [.new, .initial])
            .eraseToAnyPublisher()
    }

    func waitingReason(for player: AVPlayer) -> AVPlayer.WaitingReason? {
        player.reasonForWaitingToPlay
    }

    private func currentDurationSeconds(for player: AVPlayer) -> Double {
        guard let item = player.currentItem else { return 0 }
        let total = CMTimeGetSeconds(item.duration)
        return total.isFinite ? total : 0
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
