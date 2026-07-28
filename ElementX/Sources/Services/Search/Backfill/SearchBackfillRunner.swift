//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// sourcery: AutoMockable
protocol SearchBackfillRunnerProtocol: AnyObject {
    /// Runs one execution of the sweep, resuming the stored cursor when there is one.
    /// - Parameter excludedRoomIDs: rooms to leave alone this time round, typically because the user
    ///   has one of them open. The caller decides; the runner has no view of the UI.
    @discardableResult
    func runOnce(excludedRoomIDs: Set<String>) async -> SearchBackfillCursor
}

/// Walks rooms backwards so their history reaches the local message search index.
///
/// The app never touches the index directly — no such API is exposed. Indexing is a side effect of
/// events passing through the SDK's event cache, so "backfill" here means nothing more than asking
/// for old pages and letting the SDK index what the network returns.
///
/// **What this cannot do, stated where the code lives.** A room whose history is already in the local
/// event cache re-hydrates from disk on pagination, and those events never reach the indexer. The
/// sweep gets the same success back either way, so it will record a clean outcome for a room into
/// which it indexed exactly nothing. Nothing here can detect that; it is why no state in this file
/// can ever report completeness.
final class SearchBackfillRunner: SearchBackfillRunnerProtocol {
    private let clientProxy: ClientProxyProtocol
    private let store: SearchBackfillStoreProtocol
    private let roomQueueProvider: () async -> [String]
    private let budget: SearchBackfillBudget
    private let timeProvider: TimeProvider
    
    init(clientProxy: ClientProxyProtocol,
         store: SearchBackfillStoreProtocol,
         roomQueueProvider: @escaping () async -> [String],
         budget: SearchBackfillBudget = .init(),
         timeProvider: TimeProvider? = nil) {
        self.clientProxy = clientProxy
        self.store = store
        self.roomQueueProvider = roomQueueProvider
        self.budget = budget
        self.timeProvider = timeProvider ?? TimeProvider(clock: ContinuousClock(), now: Date.init)
    }
    
    @discardableResult
    func runOnce(excludedRoomIDs: Set<String> = []) async -> SearchBackfillCursor {
        let startedAt = timeProvider.now()
        var cursor = await resumeOrStartGeneration(startedAt: startedAt)
        
        guard !cursor.queue.isEmpty else {
            MXLog.info("Search backfill: nothing to sweep")
            cursor.finishedAt = timeProvider.now()
            await store.save(cursor)
            return cursor
        }
        
        var pagesThisExecution = 0
        var requeued = Set<String>()
        
        while !cursor.isDrained {
            guard !Task.isCancelled else {
                MXLog.info("Search backfill: cancelled at index \(cursor.index)")
                break
            }
            guard pagesThisExecution < budget.maxPagesPerExecution else {
                MXLog.info("Search backfill: page budget spent after \(pagesThisExecution) pages")
                cursor.stoppedByBudget = true
                break
            }
            guard timeProvider.now().timeIntervalSince(startedAt) < budget.executionDeadline.timeInterval else {
                MXLog.info("Search backfill: execution deadline reached")
                cursor.stoppedByBudget = true
                break
            }
            guard let roomID = cursor.currentRoomID else {
                break
            }
            
            if excludedRoomIDs.contains(roomID) {
                // The room the user is looking at: a second live timeline paginating it would issue
                // undeduplicated requests and make items jump around underneath them. Move it to the
                // back of the generation rather than consuming it, so a later execution — by which
                // point the user has usually moved on — still sweeps it. Without this, the room
                // someone opens search in is the one room a budget-stopped generation never covers.
                //
                // At most once per execution: a room the user keeps open must not grow the queue
                // every time the cursor passes it.
                cursor.index += 1
                if requeued.insert(roomID).inserted {
                    cursor.queue.append(roomID)
                } else {
                    cursor.outcomes[roomID] = .pageCap
                }
                await store.save(cursor)
                continue
            }
            
            let result = await sweepRoom(roomID: roomID,
                                         remainingPages: budget.maxPagesPerExecution - pagesThisExecution)
            
            cursor.index += 1
            cursor.pagesDone[roomID] = result.pagesIssued
            cursor.outcomes[roomID] = result.outcome
            cursor.pagesIssued += result.pagesIssued
            if result.outcome == .failed {
                cursor.failures[roomID] = (cursor.failures[roomID] ?? 0) + 1
            }
            pagesThisExecution += result.pagesIssued
            
            // Persisted after every room so process death costs at most one room of progress.
            await store.save(cursor)
            
            if !cursor.isDrained {
                try? await timeProvider.clock.sleep(for: budget.delayBetweenRooms)
            }
        }
        
        cursor.finishedAt = timeProvider.now()
        await store.save(cursor)
        MXLog.info("Search backfill: \(cursor.index)/\(cursor.queue.count) rooms visited, \(cursor.pagesIssued) pages issued")
        
        return cursor
    }
    
    // MARK: - Private
    
    private func resumeOrStartGeneration(startedAt: Date) async -> SearchBackfillCursor {
        let stored = await store.cursor()
        
        if let stored, !stored.isDrained {
            MXLog.info("Search backfill: resuming generation \(stored.generation) at index \(stored.index)")
            return stored
        }
        
        let queue = await roomQueueProvider()
        MXLog.info("Search backfill: starting a generation with \(queue.count) rooms")
        
        return SearchBackfillCursor(generation: (stored?.generation ?? 0) + 1,
                                    queue: queue,
                                    startedAt: startedAt)
    }
    
    private func sweepRoom(roomID: String, remainingPages: Int) async -> RoomResult {
        // Started before resolving the room, not after: `roomForIdentifier` can wait on a room list
        // sync, and a clock started afterwards would leave that wait outside every budget.
        let roomStartedAt = timeProvider.now()
        
        // Deliberately never subscribes: `subscribeForUpdates()` registers the room with the room
        // list service, which exposes no way to unsubscribe, so sweeping every room would
        // permanently grow the session's subscription set. Pagination does not need it.
        guard case let .joined(roomProxy) = await clientProxy.roomForIdentifier(roomID) else {
            MXLog.info("Search backfill: room is no longer joined, skipping")
            return RoomResult(outcome: .notJoined, pagesIssued: 0)
        }
        var pages = 0
        var failures = 0
        
        while pages < budget.maxPagesPerRoom, pages < remainingPages {
            guard !Task.isCancelled else { break }
            
            guard timeProvider.now().timeIntervalSince(roomStartedAt) < budget.maxRoomDuration.timeInterval else {
                return RoomResult(outcome: .pageCap, pagesIssued: pages)
            }
            
            let result = await roomProxy.timeline.paginateBackwards(requestSize: budget.pageSize)
            pages += 1
            
            switch result {
            case .success(let reachedStart):
                failures = 0
                if reachedStart {
                    return RoomResult(outcome: .reachedStart, pagesIssued: pages)
                }
            case .failure(let error):
                failures += 1
                // Room IDs are safe to log; message content never is.
                MXLog.warning("Search backfill: pagination failed for \(roomID) (\(failures)): \(error)")
                if failures >= budget.maxFailuresPerRoom {
                    return RoomResult(outcome: .failed, pagesIssued: pages)
                }
            }
            
            try? await timeProvider.clock.sleep(for: budget.delayBetweenPages)
        }
        
        return RoomResult(outcome: .pageCap, pagesIssued: pages)
    }
    
    private struct RoomResult {
        let outcome: RoomSweepOutcome
        let pagesIssued: Int
    }
}

private extension Duration {
    var timeInterval: TimeInterval {
        TimeInterval(components.seconds) + TimeInterval(components.attoseconds) / 1e18
    }
}
