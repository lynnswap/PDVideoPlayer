import Testing
@testable import PDVideoPlayer

@Test func phasefulScrubResumesEvenWhenEndHasNoDelta() {
    var machine = TrackpadScrubStateMachine()

    let beginActions = machine.handle(input(deltaX: 20, phase: .began, isPlaying: true))
    #expect(containsPause(beginActions))
    #expect(containsSetTracking(beginActions, value: true))
    #expect(containsSetScrubbing(beginActions, value: true))
    #expect(containsSeek(beginActions))

    let endActions = machine.handle(input(deltaX: 0, deltaY: 0, phase: .ended, isPlaying: false))
    #expect(containsSnapSeek(endActions))
    #expect(containsSetTracking(endActions, value: false))
    #expect(containsSetScrubbing(endActions, value: false))
    #expect(containsPlay(endActions))
}

@Test func phaseLessScrubFinishesOnTimeout() {
    var machine = TrackpadScrubStateMachine(phaseLessEndDelayNanoseconds: 1)

    let startActions = machine.handle(input(deltaX: 12, phase: .none, isPlaying: true))
    #expect(containsPause(startActions))
    #expect(containsSchedulePhaseLessEnd(startActions))

    let timeoutActions = machine.handlePhaseLessEndTimeout()
    #expect(containsSnapSeek(timeoutActions))
    #expect(containsPlay(timeoutActions))
}

@Test func repeatedScrubsPauseEachTime() {
    var machine = TrackpadScrubStateMachine()

    let firstBegin = machine.handle(input(deltaX: 10, phase: .began, isPlaying: true))
    #expect(containsPause(firstBegin))
    #expect(containsSetScrubbing(firstBegin, value: true))

    _ = machine.handle(input(deltaX: 0, phase: .ended, isPlaying: false))

    let secondBegin = machine.handle(input(deltaX: 8, phase: .began, isPlaying: true))
    #expect(containsPause(secondBegin))
    #expect(containsSetScrubbing(secondBegin, value: true))
}

@Test func verticalScrollDoesNotStartScrub() {
    var machine = TrackpadScrubStateMachine()

    let actions = machine.handle(input(deltaX: 0, deltaY: 12, phase: .began, isPlaying: true))
    #expect(actions.isEmpty)
}

@Test func verticalScrollDuringScrubIsIgnored() {
    var machine = TrackpadScrubStateMachine()

    _ = machine.handle(input(deltaX: 10, phase: .began, isPlaying: true))
    let actions = machine.handle(input(deltaX: 0, deltaY: 12, phase: .changed, isPlaying: false))

    #expect(actions.isEmpty)
    #expect(machine.isScrubbing == true)
}

@Test func phasefulEventCancelsPhaseLessSchedule() {
    var machine = TrackpadScrubStateMachine()

    _ = machine.handle(input(deltaX: 10, phase: .none, isPlaying: true))
    let actions = machine.handle(input(deltaX: 5, phase: .changed, isPlaying: false))

    #expect(containsCancelPhaseLessEnd(actions))
}

@Test func momentumEventsAreIgnored() {
    var machine = TrackpadScrubStateMachine()

    let actions = machine.handle(input(deltaX: 10, phase: .began, hasMomentum: true, isPlaying: true))
    #expect(actions.isEmpty)
}

private func input(
    deltaX: Double,
    deltaY: Double = 0,
    phase: TrackpadScrubStateMachine.Phase = .changed,
    hasMomentum: Bool = false,
    precise: Bool = true,
    inverted: Bool = false,
    currentTime: Double = 10,
    duration: Double = 100,
    isPlaying: Bool = true
) -> TrackpadScrubStateMachine.Input {
    TrackpadScrubStateMachine.Input(
        phase: phase,
        hasMomentum: hasMomentum,
        deltaX: deltaX,
        deltaY: deltaY,
        isDirectionInvertedFromDevice: inverted,
        hasPreciseDeltas: precise,
        currentTime: currentTime,
        duration: duration,
        isPlaying: isPlaying
    )
}

private func containsPause(_ actions: [TrackpadScrubStateMachine.Action]) -> Bool {
    actions.contains { if case .pause = $0 { true } else { false } }
}

private func containsPlay(_ actions: [TrackpadScrubStateMachine.Action]) -> Bool {
    actions.contains { if case .play = $0 { true } else { false } }
}

private func containsSetTracking(_ actions: [TrackpadScrubStateMachine.Action], value: Bool) -> Bool {
    actions.contains {
        if case let .setTracking(state) = $0 { return state == value }
        return false
    }
}

private func containsSetScrubbing(_ actions: [TrackpadScrubStateMachine.Action], value: Bool) -> Bool {
    actions.contains {
        if case let .setScrubbing(state) = $0 { return state == value }
        return false
    }
}

private func containsSeek(_ actions: [TrackpadScrubStateMachine.Action]) -> Bool {
    actions.contains { if case .seek = $0 { true } else { false } }
}

private func containsSnapSeek(_ actions: [TrackpadScrubStateMachine.Action]) -> Bool {
    actions.contains { if case .snapSeek = $0 { true } else { false } }
}

private func containsSchedulePhaseLessEnd(_ actions: [TrackpadScrubStateMachine.Action]) -> Bool {
    actions.contains { if case .schedulePhaseLessEnd = $0 { true } else { false } }
}

private func containsCancelPhaseLessEnd(_ actions: [TrackpadScrubStateMachine.Action]) -> Bool {
    actions.contains { if case .cancelPhaseLessEnd = $0 { true } else { false } }
}
