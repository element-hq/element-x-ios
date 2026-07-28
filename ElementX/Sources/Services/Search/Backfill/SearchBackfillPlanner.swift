//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Decides which rooms to back-paginate, and in what order.
///
/// Pure on purpose: this is the one part of the sweep whose behaviour a unit test can fully pin down,
/// so all the judgement lives here and the runner stays a dumb loop.
///
/// Ordering is most-recently-active first, so the rooms a user is most likely to search become
/// searchable soonest. The sort is explicit and not inherited: the room list replays the SDK's diffs
/// verbatim and applies no app-side ordering, so relying on the incoming order would be relying on an
/// accident.
enum SearchBackfillPlanner {
    /// Maps room summaries to the queue of room IDs for one sweep generation.
    ///
    /// Only IDs are returned, never the summaries themselves: a `RoomSummary` holds a live Rust room
    /// handle, and a queue of 100 of them would pin 100 handles for the length of the sweep.
    static func plan(summaries: [RoomSummary], limit: Int) -> [String] {
        var seen = Set<String>()
        
        return summaries
            .filter { summary in
                // Spaces are containers and hold no messages to index.
                guard !summary.isSpace else { return false }
                // A tombstoned room's history is frozen and lives on under the predecessor's ID, so
                // paginating the successor spends network on nothing.
                guard !summary.isTombstoned else { return false }
                // Invites and knocks have no history to walk back into. This does not exclude banned
                // rooms — the room list filter admits them and no summary field distinguishes one —
                // so the runner's membership check is what finally rejects those, at no network cost.
                guard summary.joinRequestType == nil else { return false }
                // No last message means nothing has ever arrived here.
                guard summary.lastMessageDate != nil else { return false }
                
                return seen.insert(summary.id).inserted
            }
            .sorted { ($0.lastMessageDate ?? .distantPast) > ($1.lastMessageDate ?? .distantPast) }
            .prefix(limit)
            .map(\.id)
    }
}
