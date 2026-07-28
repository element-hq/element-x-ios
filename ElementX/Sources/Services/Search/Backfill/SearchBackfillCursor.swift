//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// How a single room's backfill ended.
///
/// Note what is deliberately missing: an outcome meaning "this room is fully indexed". The app cannot
/// know that. Back-paginating a room whose history is already in the local event cache re-hydrates it
/// from disk, and pagination reports exactly the same success as a network fetch that indexed
/// everything. ``reachedStart`` therefore means "there was nothing left to ask for", not "it is all
/// searchable".
nonisolated enum RoomSweepOutcome: String, Codable, Equatable {
    /// Pagination reported the start of the room. Says nothing about how much was indexed.
    case reachedStart
    /// Stopped at the per-room page cap or time limit. More history exists.
    case pageCap
    /// Pagination failed repeatedly for this room.
    case failed
    /// The room was no longer joined by the time its turn came.
    case notJoined
}

/// Durable position of the sweep, so it survives process death instead of restarting from zero.
///
/// ``queue`` is frozen when a generation starts. It is deliberately not recomputed as the sweep runs:
/// it is ordered by the room's latest message date, which changes on every incoming message, so
/// recomputing mid-sweep would reshuffle rooms underneath the cursor and could starve a room forever.
nonisolated struct SearchBackfillCursor: Codable, Equatable {
    var generation = 0
    var queue: [String] = []
    var index = 0
    var pagesDone: [String: Int] = [:]
    var failures: [String: Int] = [:]
    var outcomes: [String: RoomSweepOutcome] = [:]
    var pagesIssued = 0
    var startedAt: Date?
    var finishedAt: Date?
    var stoppedByBudget = false
    
    var isDrained: Bool {
        index >= queue.count
    }
    
    /// True when another execution is needed to make progress: rooms remain unvisited, or the queue
    /// was empty when the generation started — typically because the room list had not synced yet in
    /// a headless start — and nothing was swept at all.
    var needsAnotherExecution: Bool {
        !isDrained || queue.isEmpty
    }
    
    var currentRoomID: String? {
        queue.indices.contains(index) ? queue[index] : nil
    }
}
