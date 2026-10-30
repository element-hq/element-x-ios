//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Keeps the timeline still while a message sent from the bottom lands. Clearing the composer resizes the timeline
/// a few frames before the echo is inserted, which would drop the rows and then push them back up. The table feeds
/// this machine events with the current time and carries out the command it returns.
nonisolated struct SendHoldMachine: Equatable {
    nonisolated enum Phase: Equatable {
        case idle
        /// The newest row is pinned until the composer has cleared and the echo has landed.
        case holding
        /// Scrolling to the bottom.
        case releasing
        /// The user dragged; the hold ends with the drag.
        case detached
    }
    
    nonisolated enum Event: Equatable {
        /// A text or reply send started. `anchorTop` is the newest row's visual top in window coordinates.
        case sendBegan(canHold: Bool, anchorTop: CGFloat?)
        case composerWillClear
        /// `rise` is how far the view's bottom edge moved up; `slot` is the empty space under the newest row.
        case viewHeightChanged(rise: CGFloat, slot: CGFloat)
        /// An update was applied while holding, with `ownEchoes` local echoes at the newest end.
        case applied(ownEchoes: Int)
        /// The anchor row was removed and the table picked another one at `top`.
        case anchorReplaced(top: CGFloat)
        case dragBegan
        /// A drag ended without decelerating, a deceleration ended, or the detached timeout passed with neither running.
        /// `isInHoldSpace` is whether the rows are in the space the hold's insets make, such as the empty slot under the
        /// newest row, which UIKit would snap them out of once the insets go.
        case dragEnded(isInHoldSpace: Bool)
        case releaseReachedBottom
        case widthChanged
        /// The table is going away or showing something else.
        case exit(scrollToBottom: Bool)
        case tick
    }
    
    nonisolated enum Command: Equatable {
        case none
        /// Pin the current newest row after every layout pass, stopping any running release.
        case startHolding
        case release
        case stopRelease
        case finish(scrollToBottom: Bool)
    }
    
    static let clearTimeout: TimeInterval = 1.5
    static let echoTimeout: TimeInterval = 1.0
    /// The composer and the keyboard can resize the view over several passes, so wait for them to stop.
    static let settleInterval: TimeInterval = 0.04
    static let releaseTimeout: TimeInterval = 0.6
    static let detachedTimeout: TimeInterval = 3.0
    
    private(set) var phase = Phase.idle
    /// The window y the anchor row's visual top is kept at while holding.
    private(set) var anchorTarget: CGFloat = 0
    private var pendingClears = 0
    private var pendingEchoes = 0
    /// The last resize, clear or own echo. Each can be followed by a layout pass that moves the rows, so the release waits for quiet after all three.
    private var lastDisturbance = -TimeInterval.infinity
    private var deadline = TimeInterval.infinity
    
    var isPinning: Bool {
        phase == .holding
    }
    
    /// Holding and releasing briefly offset the rows while they're logically at the bottom.
    var keepsTimelineAtBottom: Bool {
        phase == .holding || phase == .releasing
    }
    
    func nextTick(after now: TimeInterval) -> TimeInterval? {
        switch phase {
        case .idle:
            nil
        case .holding where pendingClears == 0 && pendingEchoes == 0:
            min(max(now, lastDisturbance + Self.settleInterval), deadline)
        case .holding, .releasing, .detached:
            deadline
        }
    }
    
    mutating func handle(_ event: Event, now: TimeInterval) -> Command {
        switch (phase, event) {
        case (.idle, .sendBegan(let canHold, let anchorTop)):
            guard canHold, let anchorTop else { return .none }
            self = SendHoldMachine()
            phase = .holding
            anchorTarget = anchorTop
            return addSend(now: now, command: .startHolding)
        case (.holding, .sendBegan):
            return addSend(now: now, command: .none)
        case (.releasing, .sendBegan(_, let anchorTop)):
            guard let anchorTop else { return .none }
            phase = .holding
            anchorTarget = anchorTop
            return addSend(now: now, command: .startHolding)
        case (.holding, .composerWillClear):
            pendingClears = max(0, pendingClears - 1)
            deadline = now + Self.echoTimeout
            lastDisturbance = now
            return .none
        case (.holding, .viewHeightChanged(let rise, let slot)):
            lastDisturbance = now
            // A growing composer or keyboard eats the empty slot first; only the rest pushes the rows up.
            if rise > 0 {
                anchorTarget -= max(0, rise - slot)
            }
            return .none
        case (.holding, .applied(let ownEchoes)):
            pendingEchoes = max(0, pendingEchoes - ownEchoes)
            if ownEchoes > 0 {
                lastDisturbance = now
            }
            return .none
        case (.holding, .anchorReplaced(let top)):
            anchorTarget = top
            return .none
        case (.holding, .dragBegan), (.releasing, .dragBegan):
            phase = .detached
            deadline = now + Self.detachedTimeout
            return .stopRelease
        case (.detached, .dragEnded(let isInHoldSpace)):
            return isInHoldSpace ? startRelease(now: now) : finish(scrollToBottom: false)
        case (.releasing, .releaseReachedBottom):
            return finish(scrollToBottom: true)
        case (.holding, .widthChanged), (.releasing, .widthChanged), (.detached, .widthChanged):
            return finish(scrollToBottom: phase != .detached)
        case (.holding, .exit(let scrollToBottom)), (.releasing, .exit(let scrollToBottom)), (.detached, .exit(let scrollToBottom)):
            return finish(scrollToBottom: scrollToBottom)
        case (.holding, .tick):
            // Same sum as `nextTick`, so a tick sent at that time always counts as settled.
            let isSettled = pendingClears == 0 && pendingEchoes == 0 && now >= lastDisturbance + Self.settleInterval
            return isSettled || now >= deadline ? startRelease(now: now) : .none
        case (.releasing, .tick):
            return now >= deadline ? finish(scrollToBottom: true) : .none
        case (.detached, .tick):
            return now >= deadline ? finish(scrollToBottom: false) : .none
        default:
            return .none
        }
    }
    
    private mutating func addSend(now: TimeInterval, command: Command) -> Command {
        pendingClears += 1
        pendingEchoes += 1
        deadline = now + Self.clearTimeout
        return command
    }
    
    private mutating func startRelease(now: TimeInterval) -> Command {
        phase = .releasing
        deadline = now + Self.releaseTimeout
        return .release
    }
    
    private mutating func finish(scrollToBottom: Bool) -> Command {
        self = SendHoldMachine()
        return .finish(scrollToBottom: scrollToBottom)
    }
}
