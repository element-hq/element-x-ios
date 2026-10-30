//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Decides whether a bubble's group style change (its sender header, top padding, corners) animates.
/// SwiftUI animates those inside the cell, so they may only animate when the table animates the same
/// update: otherwise the bubble tweens inside a row whose height has already snapped.
nonisolated enum RegroupPolicy {
    nonisolated enum Cause: Equatable {
        case backPagination
        /// A new newest item while one of our composer sends is in flight: the table may be holding, so nothing tweens.
        case insertDuringSend
        case newestInsert
        case other
    }
    
    /// Shown above the oldest row while a page loads, so it isn't history.
    private static let backwardSpinnerID = PaginationIndicatorRoomTimelineItem(position: .start).id.uniqueID
    
    /// IDs oldest first, as the view model holds them.
    static func cause(oldIDs: [TimelineItemIdentifier.UniqueID],
                      newIDs: [TimelineItemIdentifier.UniqueID],
                      isSendInFlight: Bool) -> Cause {
        guard let oldNewest = oldIDs.last, let newNewest = newIDs.last else { return .other }
        
        if newNewest != oldNewest, !oldIDs.contains(newNewest) {
            return isSendInFlight ? .insertDuringSend : .newestInsert
        }
        return addsHistory(oldIDs: oldIDs, newIDs: newIDs) ? .backPagination : .other
    }
    
    static func animatesGroupStyleChange(for cause: Cause) -> Bool {
        switch cause {
        case .newestInsert: true
        case .backPagination, .insertDuringSend, .other: false
        }
    }
    
    /// Whether the rows an update changes in place animate their resizes. The table animates all of an update's
    /// resizes when it animates one, so this is decided once per update: when a sender header or top padding comes or
    /// goes without animation, every row the update changes resizes without animation, or that bubble would jump.
    static func animatesResizes(for cause: Cause, togglesSenderDetails: Bool) -> Bool {
        animatesGroupStyleChange(for: cause) || !togglesSenderDetails
    }
    
    /// A page moves the oldest surviving row down the list. The spinner coming or going doesn't count, and nor
    /// does a replaced top date divider, which is why this doesn't just look for the old first ID.
    private static func addsHistory(oldIDs: [TimelineItemIdentifier.UniqueID], newIDs: [TimelineItemIdentifier.UniqueID]) -> Bool {
        let oldHistory = oldIDs.filter { $0 != backwardSpinnerID }
        let newHistory = newIDs.filter { $0 != backwardSpinnerID }
        let newHistorySet = Set(newHistory)
        guard let oldIndex = oldHistory.firstIndex(where: newHistorySet.contains),
              let newIndex = newHistory.firstIndex(of: oldHistory[oldIndex]) else {
            return false
        }
        return newIndex > oldIndex
    }
}

extension RegroupPolicy {
    /// While the table may be holding the timeline still for a composer send: from the send until the composer
    /// has cleared and the echo has landed. The view model can't see the table, so this follows the hold's own
    /// rules, with its timeouts as the outer limit for a send that never clears or echoes.
    nonisolated struct SendWindow: Equatable {
        /// The send hold's longest waits: for the composer to clear, then for the echo after the clear.
        static let clearTimeout: TimeInterval = 1.5
        static let echoTimeout: TimeInterval = 1.0
        
        private var pendingClears = 0
        private var pendingEchoes = 0
        private var deadline = -TimeInterval.infinity
        
        /// `now` is monotonic time, such as `ProcessInfo.systemUptime`.
        func isOpen(at now: TimeInterval) -> Bool {
            (pendingClears > 0 || pendingEchoes > 0) && now < deadline
        }
        
        mutating func sendBegan(at now: TimeInterval) {
            closeIfExpired(at: now)
            pendingClears += 1
            pendingEchoes += 1
            deadline = max(deadline, now + Self.clearTimeout + Self.echoTimeout)
        }
        
        mutating func composerCleared(at now: TimeInterval) {
            closeIfExpired(at: now)
            guard pendingClears > 0 else { return }
            pendingClears -= 1
            deadline = max(deadline, now + Self.echoTimeout)
        }
        
        /// Counts the update's local echoes against the sends in flight.
        /// - Parameters:
        ///   - oldIDs: The IDs before the update, oldest first.
        ///   - newIDs: The identifiers after the update, oldest first.
        /// - Returns: Whether the update landed during a send, the echoes it brings included.
        mutating func updateArrived(oldIDs: [TimelineItemIdentifier.UniqueID], newIDs: [TimelineItemIdentifier], at now: TimeInterval) -> Bool {
            closeIfExpired(at: now)
            guard isOpen(at: now) else { return false }
            
            pendingEchoes = max(0, pendingEchoes - Self.newLocalEchoCount(oldIDs: oldIDs, newIDs: newIDs))
            return true
        }
        
        /// Echoes land at the newest end, unlike history, and only our own sends have a transaction ID.
        private static func newLocalEchoCount(oldIDs: [TimelineItemIdentifier.UniqueID], newIDs: [TimelineItemIdentifier]) -> Int {
            let oldIDs = Set(oldIDs)
            return newIDs.reversed()
                .prefix { !oldIDs.contains($0.uniqueID) }
                .count { $0.transactionID != nil }
        }
        
        private mutating func closeIfExpired(at now: TimeInterval) {
            if now >= deadline {
                pendingClears = 0
                pendingEchoes = 0
            }
        }
    }
}
