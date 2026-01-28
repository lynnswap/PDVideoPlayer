import Foundation
import AVFoundation
import Combine

@MainActor
final class PlayerEngine {
    private(set) var player: AVPlayer

    private var cancellables = Set<AnyCancellable>()
    private var itemStatusCancellable: AnyCancellable?
    private var timeTask: Task<Void, Never>?
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

    func startObserving(
        onTime: @MainActor @escaping (Double, Double) -> Void,
        onStatus: @MainActor @escaping (AVPlayer.TimeControlStatus, AVPlayer.WaitingReason?) -> Void,
        onItemReady: @MainActor @escaping () -> Void
    ) {
        stopObserving()
        player.appliesMediaSelectionCriteriaAutomatically = false

        let (initialTime, initialDuration) = observer.initialTime(for: player)
        onTime(initialTime.isFinite ? initialTime : 0, initialDuration)

        observer.timeControlStatusPublisher(for: player)
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    onStatus(status, self.player.reasonForWaitingToPlay)
                }
            }
            .store(in: &cancellables)

        observer.currentItemPublisher(for: player)
            .receive(on: RunLoop.main)
            .sink { [weak self] item in
                guard let self else { return }
                self.itemStatusCancellable?.cancel()
                self.itemStatusCancellable = nil
                guard let item else { return }
                self.itemStatusCancellable = self.observer.itemStatusPublisher(for: item)
                    .receive(on: RunLoop.main)
                    .sink { status in
                        if status == .readyToPlay {
                            Task { @MainActor in
                                onItemReady()
                            }
                        }
                    }
            }
            .store(in: &cancellables)

        let stream = observer.timeStream(for: player)
        timeTask = Task { @MainActor [weak self] in
            for await time in stream {
                guard let self else { return }
                if Task.isCancelled { break }
                let current = CMTimeGetSeconds(time)
                let duration = self.currentDurationSeconds()
                onTime(current.isFinite ? current : 0, duration)
            }
        }
    }

    func stopObserving() {
        timeTask?.cancel()
        timeTask = nil
        itemStatusCancellable?.cancel()
        itemStatusCancellable = nil
        cancellables.removeAll()
    }

    private func currentDurationSeconds() -> Double {
        guard let item = player.currentItem else { return 0 }
        let total = CMTimeGetSeconds(item.duration)
        return total.isFinite ? total : 0
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
