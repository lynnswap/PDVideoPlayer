import Foundation
import AVFoundation
import Combine

@MainActor
final class PlayerEngine {
    private(set) var player: AVPlayer

    private var cancellables = Set<AnyCancellable>()
    private var itemStatusCancellable: AnyCancellable?
    private var timeTask: Task<Void, Never>?

    init(player: AVPlayer) {
        self.player = player
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

        let initialDuration = currentDurationSeconds()
        let initialTime = CMTimeGetSeconds(player.currentTime())
        onTime(initialTime.isFinite ? initialTime : 0, initialDuration)

        player.publisher(for: \.timeControlStatus)
            .receive(on: RunLoop.main)
            .sink { [weak self] status in
                Task { @MainActor [weak self] in
                    guard let self else { return }
                    onStatus(status, self.player.reasonForWaitingToPlay)
                }
            }
            .store(in: &cancellables)

        player.publisher(for: \.currentItem, options: [.new, .initial])
            .receive(on: RunLoop.main)
            .sink { [weak self] item in
                guard let self else { return }
                self.itemStatusCancellable?.cancel()
                self.itemStatusCancellable = nil
                guard let item else { return }
                self.itemStatusCancellable = item.publisher(for: \.status, options: [.new, .initial])
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

        let stream = player.periodicTimeStream(
            forInterval: CMTime(value: 1, timescale: 30),
            queue: .main
        )
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
