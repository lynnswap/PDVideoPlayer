#if canImport(Foundation)
import Foundation
#endif

struct TrackpadScrubStateMachine {
    enum Phase {
        case began
        case changed
        case ended
        case cancelled
        case none
    }

    struct Input {
        var phase: Phase
        var hasMomentum: Bool
        var deltaX: Double
        var deltaY: Double
        var isDirectionInvertedFromDevice: Bool
        var hasPreciseDeltas: Bool
        var currentTime: Double
        var duration: Double
        var isPlaying: Bool
    }

    enum Action {
        case pause
        case play
        case setTracking(Bool)
        case setScrubbing(Bool)
        case seek(Double)
        case snapSeek(Double)
        case schedulePhaseLessEnd(delayNanoseconds: UInt64)
        case cancelPhaseLessEnd
    }

    private(set) var isScrubbing = false
    private var wasPlayingBeforeScrub = false
    private var ratioValue: Double = 0
    private var scrubDuration: Double = 0
    private let phaseLessEndDelayNanoseconds: UInt64
    private let snapStepSeconds: Double = 0.03

    init(phaseLessEndDelayNanoseconds: UInt64 = 200_000_000) {
        self.phaseLessEndDelayNanoseconds = phaseLessEndDelayNanoseconds
    }

    mutating func handle(_ input: Input) -> [Action] {
        guard input.duration > 0 else { return [] }

        let isPhaseLess = input.phase == .none
        let isEnded = input.phase == .ended || input.phase == .cancelled
        let isHorizontal = abs(input.deltaX) > abs(input.deltaY)

        if isEnded {
            return finishIfNeeded()
        }

        if input.hasMomentum { return [] }
        guard isHorizontal else { return [] }

        var actions: [Action] = []

        if !isScrubbing {
            actions.append(contentsOf: beginActions(with: input))
        }

        actions.append(contentsOf: updateActions(with: input))

        if isPhaseLess {
            actions.append(.schedulePhaseLessEnd(delayNanoseconds: phaseLessEndDelayNanoseconds))
        } else {
            actions.append(.cancelPhaseLessEnd)
        }

        return actions
    }

    mutating func handlePhaseLessEndTimeout() -> [Action] {
        return finishIfNeeded()
    }

    private mutating func beginActions(with input: Input) -> [Action] {
        ratioValue = input.currentTime / input.duration
        scrubDuration = input.duration
        wasPlayingBeforeScrub = input.isPlaying
        isScrubbing = true
        return [
            .pause,
            .setTracking(true),
            .setScrubbing(true)
        ]
    }

    private mutating func updateActions(with input: Input) -> [Action] {
        let sign: Double = input.isDirectionInvertedFromDevice ? 1 : -1
        let sensitivity: Double = input.hasPreciseDeltas ? 0.002 : 0.0003
        let duration = scrubDuration > 0 ? scrubDuration : input.duration
        ratioValue = min(max(ratioValue + input.deltaX * sign * sensitivity, 0), 1)
        return [.seek(ratioValue * duration)]
    }

    private mutating func finishIfNeeded() -> [Action] {
        guard isScrubbing else { return [] }

        isScrubbing = false
        let duration = scrubDuration > 0 ? scrubDuration : 0
        let snapped = duration == 0 ? 0 : (ratioValue * duration / snapStepSeconds).rounded() * snapStepSeconds
        var actions: [Action] = [
            .cancelPhaseLessEnd,
            .snapSeek(snapped),
            .setTracking(false),
            .setScrubbing(false)
        ]
        if wasPlayingBeforeScrub {
            actions.append(.play)
        }
        return actions
    }
}
