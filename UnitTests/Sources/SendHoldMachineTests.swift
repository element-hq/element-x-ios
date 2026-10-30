//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct SendHoldMachineTests {
    @Test
    func aSendThatCanHoldStartsHolding() {
        var machine = SendHoldMachine()
        #expect(machine.handle(.sendBegan(canHold: true, anchorTop: 500), now: 0) == .startHolding)
        #expect(machine.phase == .holding)
        #expect(machine.anchorTarget == 500)
    }
    
    @Test
    func aSendThatCannotHoldDoesNothing() {
        var machine = SendHoldMachine()
        #expect(machine.handle(.sendBegan(canHold: false, anchorTop: 500), now: 0) == .none)
        #expect(machine.phase == .idle)
    }
    
    @Test(arguments: [true, false])
    func releasesAfterClearEchoAndAQuietPeriodInEitherOrder(clearFirst: Bool) {
        var machine = holding()
        let first: SendHoldMachine.Event = clearFirst ? .composerWillClear : .applied(ownEchoes: 1)
        let second: SendHoldMachine.Event = clearFirst ? .applied(ownEchoes: 1) : .composerWillClear
        _ = machine.handle(first, now: 0.05)
        _ = machine.handle(second, now: 0.06)
        #expect(machine.handle(.tick, now: 0.07) == .none)
        #expect(machine.nextTick(after: 0.07) == 0.06 + SendHoldMachine.settleInterval)
        #expect(machine.handle(.tick, now: 0.06 + SendHoldMachine.settleInterval) == .release)
    }
    
    @Test
    func aClearThatFollowsTheEchoWaitsForTheComposerToResize() {
        var machine = holding()
        _ = machine.handle(.applied(ownEchoes: 1), now: 0.05)
        _ = machine.handle(.composerWillClear, now: 0.2)
        #expect(machine.nextTick(after: 0.2) == 0.2 + SendHoldMachine.settleInterval)
        #expect(machine.handle(.tick, now: 0.2) == .none)
        
        // The composer's smaller size lands a frame after the clear and is still absorbed by the pin.
        _ = machine.handle(.viewHeightChanged(rise: -40, slot: 0), now: 0.216)
        #expect(machine.handle(.tick, now: 0.24) == .none)
        #expect(machine.phase == .holding)
        #expect(machine.handle(.tick, now: 0.216 + SendHoldMachine.settleInterval) == .release)
    }
    
    @Test
    func anEchoThatFollowsTheClearWaitsForTheRowsToSettle() {
        var machine = holding()
        _ = machine.handle(.composerWillClear, now: 0.05)
        _ = machine.handle(.applied(ownEchoes: 1), now: 0.3)
        #expect(machine.nextTick(after: 0.3) == 0.3 + SendHoldMachine.settleInterval)
        #expect(machine.handle(.tick, now: 0.31) == .none)
        #expect(machine.handle(.tick, now: 0.3 + SendHoldMachine.settleInterval) == .release)
    }
    
    @Test
    func aForeignRowDoesNotRestartTheQuietPeriod() {
        var machine = holding()
        _ = machine.handle(.composerWillClear, now: 0.05)
        _ = machine.handle(.applied(ownEchoes: 1), now: 0.06)
        _ = machine.handle(.applied(ownEchoes: 0), now: 0.09)
        #expect(machine.nextTick(after: 0.09) == 0.06 + SendHoldMachine.settleInterval)
    }
    
    @Test
    func aResizeDelaysTheReleaseUntilQuiet() throws {
        var machine = holding()
        _ = machine.handle(.composerWillClear, now: 0.05)
        _ = machine.handle(.applied(ownEchoes: 1), now: 0.06)
        _ = machine.handle(.viewHeightChanged(rise: -40, slot: 0), now: 0.07)
        #expect(machine.handle(.tick, now: 0.09) == .none)
        let next = try #require(machine.nextTick(after: 0.09))
        #expect(abs(next - 0.11) < 0.0001)
        #expect(machine.handle(.tick, now: next) == .release)
    }
    
    @Test
    func foreignRowsDoNotCountAsTheEcho() {
        var machine = holding()
        _ = machine.handle(.composerWillClear, now: 0.05)
        _ = machine.handle(.applied(ownEchoes: 0), now: 0.06)
        #expect(machine.handle(.tick, now: 0.2) == .none)
        #expect(machine.phase == .holding)
    }
    
    @Test
    func missingEchoReleasesAtTheEchoTimeout() {
        var machine = holding()
        _ = machine.handle(.composerWillClear, now: 0.05)
        #expect(machine.handle(.tick, now: 0.05 + SendHoldMachine.echoTimeout) == .release)
    }
    
    @Test
    func missingClearReleasesAtTheClearTimeout() {
        var machine = holding()
        #expect(machine.handle(.tick, now: SendHoldMachine.clearTimeout) == .release)
    }
    
    @Test
    func aReleaseFinishesAtTheBottomOrAtItsTimeout() {
        var machine = releasing()
        #expect(machine.handle(.releaseReachedBottom, now: 0.3) == .finish(scrollToBottom: true))
        #expect(machine.phase == .idle)
        
        var stuck = releasing()
        #expect(stuck.handle(.tick, now: 0.2 + SendHoldMachine.releaseTimeout) == .finish(scrollToBottom: true))
    }
    
    @Test
    func aSecondSendWhileHoldingNeedsBothEchoes() {
        var machine = holding()
        _ = machine.handle(.sendBegan(canHold: true, anchorTop: 480), now: 0.02)
        _ = machine.handle(.composerWillClear, now: 0.05)
        _ = machine.handle(.composerWillClear, now: 0.06)
        _ = machine.handle(.applied(ownEchoes: 1), now: 0.07)
        #expect(machine.handle(.tick, now: 0.2) == .none)
        _ = machine.handle(.applied(ownEchoes: 1), now: 0.21)
        #expect(machine.handle(.tick, now: 0.26) == .release)
    }
    
    @Test
    func aSecondSendWhileReleasingHoldsAgain() {
        var machine = releasing()
        #expect(machine.handle(.sendBegan(canHold: true, anchorTop: 420), now: 0.3) == .startHolding)
        #expect(machine.phase == .holding)
        #expect(machine.anchorTarget == 420)
    }
    
    @Test
    func aSendWhileDetachedIsIgnored() {
        var machine = holding()
        _ = machine.handle(.dragBegan, now: 0.1)
        #expect(machine.handle(.sendBegan(canHold: true, anchorTop: 400), now: 0.2) == .none)
        #expect(machine.phase == .detached)
    }
    
    @Test
    func aDragDetachesAndStopsAnyRelease() {
        var machine = releasing()
        #expect(machine.handle(.dragBegan, now: 0.3) == .stopRelease)
        #expect(!machine.isPinning)
        #expect(!machine.keepsTimelineAtBottom)
    }
    
    @Test
    func aDetachedHoldSettlesOnDragEnd() {
        var inHoldSpace = detached()
        #expect(inHoldSpace.handle(.dragEnded(isInHoldSpace: true), now: 0.5) == .release)
        var outOfHoldSpace = detached()
        #expect(outOfHoldSpace.handle(.dragEnded(isInHoldSpace: false), now: 0.5) == .finish(scrollToBottom: false))
    }
    
    @Test
    func aDetachedHoldTimesOut() {
        var machine = detached()
        #expect(machine.handle(.tick, now: 0.1 + SendHoldMachine.detachedTimeout) == .finish(scrollToBottom: false))
    }
    
    @Test
    func widthChangeFinishesAtTheBottom() {
        var machine = holding()
        #expect(machine.handle(.widthChanged, now: 0.1) == .finish(scrollToBottom: true))
        var dragged = detached()
        #expect(dragged.handle(.widthChanged, now: 0.2) == .finish(scrollToBottom: false))
    }
    
    @Test
    func aShorterViewUsesTheEmptySlotFirst() {
        var machine = holding()
        _ = machine.handle(.viewHeightChanged(rise: 50, slot: 20), now: 0.1)
        #expect(machine.anchorTarget == 470)
        _ = machine.handle(.viewHeightChanged(rise: 10, slot: 20), now: 0.2)
        #expect(machine.anchorTarget == 470)
        _ = machine.handle(.viewHeightChanged(rise: -60, slot: 0), now: 0.3)
        #expect(machine.anchorTarget == 470)
    }
    
    // Ticks fire at `nextTick` between the events, and a spacing of 0.06 leaves room for the quiet period to pass between them.
    @Test(arguments: [0.03, 0.06])
    func everyOrderingOfTheEventsEndsWithoutAnEarlyRelease(spacing: TimeInterval) {
        let events: [SendHoldMachine.Event] = [.composerWillClear, .viewHeightChanged(rise: -40, slot: 0), .applied(ownEchoes: 1), .applied(ownEchoes: 0),
                                               .sendBegan(canHold: true, anchorTop: 480), .dragBegan, .dragEnded(isInHoldSpace: true), .widthChanged]
        for order in permutations(events) {
            var simulation = HoldSimulation()
            simulation.send(.sendBegan(canHold: true, anchorTop: 500), after: 0)
            for event in order {
                simulation.send(event, after: spacing)
            }
            simulation.runOut()
            #expect(simulation.violations.isEmpty, "\(order): \(simulation.violations)")
        }
    }
    
    // Long pauses reach the timeouts, which no ordering of closely spaced events does.
    @Test
    func randomSequencesWithLongPausesEndWithoutAnEarlyRelease() {
        let events: [SendHoldMachine.Event] = [.sendBegan(canHold: true, anchorTop: 480), .composerWillClear, .composerWillClear, .applied(ownEchoes: 1), .applied(ownEchoes: 1),
                                               .applied(ownEchoes: 0), .viewHeightChanged(rise: -40, slot: 0), .viewHeightChanged(rise: 25, slot: 10), .dragBegan,
                                               .dragEnded(isInHoldSpace: true), .dragEnded(isInHoldSpace: false), .releaseReachedBottom, .widthChanged, .tick]
        let pauses: [TimeInterval] = [0.005, 0.02, 0.03, 0.05, 0.2, 0.7, 1.05, 1.6, 3.2]
        var generator = SeededGenerator(seed: 7)
        var timeoutReleases = 0
        var releaseTimeouts = 0
        var detachedTimeouts = 0
        var reholds = 0
        
        for _ in 0..<3000 {
            var simulation = HoldSimulation()
            simulation.send(.sendBegan(canHold: true, anchorTop: 500), after: 0)
            for _ in 0..<Int.random(in: 2...12, using: &generator) {
                let event = events[Int.random(in: events.indices, using: &generator)]
                simulation.send(event, after: pauses[Int.random(in: pauses.indices, using: &generator)])
            }
            simulation.runOut()
            #expect(simulation.violations.isEmpty, "\(simulation.violations)")
            
            timeoutReleases += simulation.timeoutReleases
            releaseTimeouts += simulation.releaseTimeouts
            detachedTimeouts += simulation.detachedTimeouts
            reholds += simulation.reholds
        }
        
        // Every path the sequences are meant to reach was reached.
        #expect(timeoutReleases > 0)
        #expect(releaseTimeouts > 0)
        #expect(detachedTimeouts > 0)
        #expect(reholds > 0)
    }
    
    @Test
    func aSendWithoutAnAnchorDoesNothing() {
        var machine = SendHoldMachine()
        #expect(machine.handle(.sendBegan(canHold: true, anchorTop: nil), now: 0) == .none)
        #expect(machine.phase == .idle)
    }
    
    @Test
    func aSecondSendWhileHoldingKeepsTheAnchor() {
        var machine = holding()
        #expect(machine.handle(.sendBegan(canHold: true, anchorTop: 480), now: 0.02) == .none)
        #expect(machine.anchorTarget == 500)
    }
    
    @Test
    func aSecondSendWithoutAnAnchorWhileReleasingKeepsReleasing() {
        var machine = releasing()
        #expect(machine.handle(.sendBegan(canHold: true, anchorTop: nil), now: 0.3) == .none)
        #expect(machine.phase == .releasing)
    }
    
    @Test
    func aLateEchoOfAnEarlierSendDoesNotStandInForTheNextOne() {
        var machine = holding()
        _ = machine.handle(.composerWillClear, now: 0.05)
        #expect(machine.handle(.tick, now: 0.05 + SendHoldMachine.echoTimeout) == .release)
        
        _ = machine.handle(.sendBegan(canHold: true, anchorTop: 420), now: 1.2)
        _ = machine.handle(.applied(ownEchoes: 1), now: 1.25)
        _ = machine.handle(.composerWillClear, now: 1.3)
        #expect(machine.handle(.tick, now: 1.4) == .none)
        #expect(machine.phase == .holding)
        
        _ = machine.handle(.applied(ownEchoes: 1), now: 1.5)
        #expect(machine.handle(.tick, now: 1.5 + SendHoldMachine.settleInterval) == .release)
    }
    
    @Test
    func aSecondSendAfterADragReleaseWaitsAtMostTheEchoTimeout() {
        // The clear and echo of the first send went unseen while detached, so the hold still counts them as owed.
        var machine = detached()
        #expect(machine.handle(.dragEnded(isInHoldSpace: true), now: 0.5) == .release)
        _ = machine.handle(.sendBegan(canHold: true, anchorTop: 420), now: 0.55)
        _ = machine.handle(.composerWillClear, now: 0.6)
        _ = machine.handle(.applied(ownEchoes: 1), now: 0.61)
        #expect(machine.handle(.tick, now: 0.7) == .none)
        #expect(machine.nextTick(after: 0.7) == 0.6 + SendHoldMachine.echoTimeout)
        #expect(machine.handle(.tick, now: 0.6 + SendHoldMachine.echoTimeout) == .release)
    }
    
    @Test
    func aSendWhileDetachedLeavesItsTimeoutAlone() {
        var machine = detached()
        _ = machine.handle(.sendBegan(canHold: true, anchorTop: 400), now: 0.2)
        #expect(machine.nextTick(after: 0.2) == 0.1 + SendHoldMachine.detachedTimeout)
    }
    
    @Test
    func theTargetOnlyMovesWhileHolding() {
        var machine = holding()
        _ = machine.handle(.anchorReplaced(top: 430), now: 0.1)
        #expect(machine.anchorTarget == 430)
        
        for var other in [releasing(), detached()] {
            _ = other.handle(.anchorReplaced(top: 300), now: 0.3)
            _ = other.handle(.viewHeightChanged(rise: 50, slot: 0), now: 0.3)
            #expect(other.anchorTarget == 500)
        }
    }
    
    @Test
    func exitFinishesAnyActiveHoldWithTheRequestedScroll() {
        for scrollToBottom in [true, false] {
            for var machine in [holding(), releasing(), detached()] {
                #expect(machine.handle(.exit(scrollToBottom: scrollToBottom), now: 0.5) == .finish(scrollToBottom: scrollToBottom))
                #expect(machine.phase == .idle)
            }
        }
    }
    
    @Test
    func anIdleMachineIgnoresEverythingButASend() {
        let events: [SendHoldMachine.Event] = [.composerWillClear, .viewHeightChanged(rise: 30, slot: 0), .applied(ownEchoes: 1), .anchorReplaced(top: 300),
                                               .dragBegan, .dragEnded(isInHoldSpace: true), .releaseReachedBottom, .widthChanged, .exit(scrollToBottom: true), .tick]
        var machine = SendHoldMachine()
        for event in events {
            #expect(machine.handle(event, now: 1) == .none)
            #expect(machine.phase == .idle)
        }
        #expect(machine.nextTick(after: 1) == nil)
    }
    
    @Test
    func theReleaseAndDragEndEventsOnlyCountInTheirOwnPhase() {
        var holdingMachine = holding()
        #expect(holdingMachine.handle(.releaseReachedBottom, now: 0.1) == .none)
        #expect(holdingMachine.handle(.dragEnded(isInHoldSpace: true), now: 0.1) == .none)
        #expect(holdingMachine.phase == .holding)
        
        var releasingMachine = releasing()
        #expect(releasingMachine.handle(.dragEnded(isInHoldSpace: false), now: 0.3) == .none)
        #expect(releasingMachine.phase == .releasing)
        
        var detachedMachine = detached()
        #expect(detachedMachine.handle(.releaseReachedBottom, now: 0.3) == .none)
        #expect(detachedMachine.phase == .detached)
    }
    
    @Test
    func aTickBeforeTheDeadlineChangesNothingWhileReleasingOrDetached() {
        var releasingMachine = releasing()
        #expect(releasingMachine.handle(.tick, now: 0.2 + SendHoldMachine.releaseTimeout - 0.01) == .none)
        #expect(releasingMachine.phase == .releasing)
        
        var detachedMachine = detached()
        #expect(detachedMachine.handle(.tick, now: 0.1 + SendHoldMachine.detachedTimeout - 0.01) == .none)
        #expect(detachedMachine.phase == .detached)
    }
    
    @Test
    func pinningAndStayingAtTheBottomFollowThePhase() {
        let idle = SendHoldMachine()
        #expect(!idle.isPinning && !idle.keepsTimelineAtBottom)
        let holdingMachine = holding()
        #expect(holdingMachine.isPinning && holdingMachine.keepsTimelineAtBottom)
        let releasingMachine = releasing()
        #expect(!releasingMachine.isPinning && releasingMachine.keepsTimelineAtBottom)
        let detachedMachine = detached()
        #expect(!detachedMachine.isPinning && !detachedMachine.keepsTimelineAtBottom)
    }
    
    @Test
    func theNextTickIsTheDeadlineUnlessTheHoldOnlyWaitsForQuiet() {
        #expect(SendHoldMachine().nextTick(after: 0) == nil)
        #expect(holding().nextTick(after: 0.1) == SendHoldMachine.clearTimeout)
        #expect(releasing().nextTick(after: 0.25) == 0.2 + SendHoldMachine.releaseTimeout)
        #expect(detached().nextTick(after: 0.2) == 0.1 + SendHoldMachine.detachedTimeout)
        
        var cleared = holding()
        _ = cleared.handle(.composerWillClear, now: 0.05)
        #expect(cleared.nextTick(after: 0.1) == 0.05 + SendHoldMachine.echoTimeout)
        
        var quiet = cleared
        _ = quiet.handle(.applied(ownEchoes: 1), now: 0.06)
        #expect(quiet.nextTick(after: 0.5) == 0.5)
    }
    
    @Test
    func extraClearsAndEchoesNeverLeaveTheHoldWaitingForNegativeCounts() {
        var machine = holding()
        _ = machine.handle(.composerWillClear, now: 0.05)
        _ = machine.handle(.composerWillClear, now: 0.06)
        _ = machine.handle(.applied(ownEchoes: 2), now: 0.07)
        #expect(machine.handle(.tick, now: 0.2) == .release)
    }
    
    @Test
    func aLateResizeCannotPostponeTheDeadline() throws {
        var machine = holding()
        _ = machine.handle(.composerWillClear, now: 0.05)
        _ = machine.handle(.applied(ownEchoes: 1), now: 0.06)
        let deadline = 0.05 + SendHoldMachine.echoTimeout
        _ = machine.handle(.viewHeightChanged(rise: -40, slot: 0), now: deadline - 0.01)
        let next = try #require(machine.nextTick(after: deadline - 0.01))
        #expect(next == deadline)
        #expect(machine.handle(.tick, now: next) == .release)
    }
    
    // MARK: - Helpers
    
    private func holding() -> SendHoldMachine {
        var machine = SendHoldMachine()
        _ = machine.handle(.sendBegan(canHold: true, anchorTop: 500), now: 0)
        return machine
    }
    
    private func releasing() -> SendHoldMachine {
        var machine = holding()
        _ = machine.handle(.composerWillClear, now: 0.05)
        _ = machine.handle(.applied(ownEchoes: 1), now: 0.06)
        _ = machine.handle(.tick, now: 0.2)
        return machine
    }
    
    private func detached() -> SendHoldMachine {
        var machine = holding()
        _ = machine.handle(.dragBegan, now: 0.1)
        return machine
    }
    
    private func permutations<T>(_ items: [T]) -> [[T]] {
        guard items.count > 1 else { return [items] }
        return items.indices.flatMap { index -> [[T]] in
            var rest = items
            let item = rest.remove(at: index)
            return permutations(rest).map { [item] + $0 }
        }
    }
}

/// Feeds a machine the way the table does: events arrive at the times given, and a tick fires at `nextTick` unless an event comes first.
/// A tick also follows every event at once, as the machine has to hold back a tick that comes before its time.
/// Apart from the machine, it tracks what the spec says the hold is still owed and records every rule the machine breaks.
private struct HoldSimulation {
    private static let longestWait = max(SendHoldMachine.clearTimeout + SendHoldMachine.releaseTimeout, SendHoldMachine.detachedTimeout)
    
    private(set) var machine = SendHoldMachine()
    private(set) var violations: [String] = []
    private(set) var timeoutReleases = 0
    private(set) var releaseTimeouts = 0
    private(set) var detachedTimeouts = 0
    private(set) var reholds = 0
    private var now: TimeInterval = 0
    
    // What the spec says the hold is owed, counted from the events that arrive while it is holding.
    private var sends = 0
    private var clears = 0
    private var echoes = 0
    private var timeout = TimeInterval.infinity
    private var lastDisturbance = -TimeInterval.infinity
    
    mutating func send(_ event: SendHoldMachine.Event, after pause: TimeInterval) {
        let time = now + pause
        fireTicks(through: time)
        now = time
        handle(event)
        handle(.tick)
    }
    
    /// Lets the remaining ticks fire, and checks that the machine then has nothing left to wait for, soon enough.
    mutating func runOut() {
        let lastEventTime = now
        fireTicks(through: .infinity)
        if machine.phase != .idle {
            violations.append("still \(machine.phase) at \(now)")
        }
        if now > lastEventTime + Self.longestWait + 0.000_001 {
            violations.append("took until \(now) after the last event at \(lastEventTime)")
        }
    }
    
    private mutating func fireTicks(through time: TimeInterval) {
        var ticks = 0
        while ticks < 20, let next = machine.nextTick(after: now), max(now, next) <= time {
            ticks += 1
            now = max(now, next)
            handle(.tick)
        }
        if ticks == 20 {
            violations.append("20 ticks in a row at \(now) without the machine settling")
        }
    }
    
    private mutating func handle(_ event: SendHoldMachine.Event) {
        let phaseBefore = machine.phase
        let command = machine.handle(event, now: now)
        
        if let expectedPhase = phase(after: command), machine.phase != expectedPhase {
            violations.append("\(command) at \(now) left the machine \(machine.phase)")
        }
        if (machine.nextTick(after: now) == nil) != (machine.phase == .idle) {
            violations.append("the next tick is \(String(describing: machine.nextTick(after: now))) while \(machine.phase), after \(event) at \(now)")
        }
        if event == .widthChanged, phaseBefore != .idle, command != .finish(scrollToBottom: phaseBefore != .detached) {
            violations.append("a width change at \(now) while \(phaseBefore) returned \(command)")
        }
        if event == .tick, phaseBefore == .holding, command == .release {
            checkRelease()
        }
        
        count(event, from: phaseBefore, command: command)
    }
    
    private func phase(after command: SendHoldMachine.Command) -> SendHoldMachine.Phase? {
        switch command {
        case .none: nil
        case .startHolding: .holding
        case .release: .releasing
        case .stopRelease: .detached
        case .finish: .idle
        }
    }
    
    private mutating func checkRelease() {
        let isOwed = clears < sends || echoes < sends
        guard now < timeout else {
            if isOwed {
                timeoutReleases += 1
            }
            return
        }
        if clears < sends {
            violations.append("released at \(now) before the clear")
        }
        if echoes < sends {
            violations.append("released at \(now) before the echo")
        }
        if now < lastDisturbance + SendHoldMachine.settleInterval {
            violations.append("released at \(now), within the quiet period after the change at \(lastDisturbance)")
        }
    }
    
    private mutating func count(_ event: SendHoldMachine.Event, from phaseBefore: SendHoldMachine.Phase, command: SendHoldMachine.Command) {
        if event == .tick, phaseBefore == .releasing, command == .finish(scrollToBottom: true) {
            releaseTimeouts += 1
        }
        if event == .tick, phaseBefore == .detached, command == .finish(scrollToBottom: false) {
            detachedTimeouts += 1
        }
        if phaseBefore == .releasing, command == .startHolding {
            reholds += 1
        }
        
        if phaseBefore == .idle, command == .startHolding {
            sends = 0
            clears = 0
            echoes = 0
            lastDisturbance = -TimeInterval.infinity
        }
        
        switch event {
        case .sendBegan where command == .startHolding || phaseBefore == .holding:
            sends += 1
            timeout = now + SendHoldMachine.clearTimeout
        case .composerWillClear where phaseBefore == .holding:
            clears += 1
            timeout = now + SendHoldMachine.echoTimeout
            lastDisturbance = now
        case .applied(let ownEchoes) where phaseBefore == .holding:
            echoes += ownEchoes
            if ownEchoes > 0 {
                lastDisturbance = now
            }
        case .viewHeightChanged where phaseBefore == .holding:
            lastDisturbance = now
        default:
            break
        }
    }
}
