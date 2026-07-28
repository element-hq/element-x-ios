//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// Durable state for the message search backfill.
//
// Kept apart from `AppSettings`: that holds user-facing settings, this holds machine state with a
// different lifetime, which must be independently resettable without touching anything the user
// chose — and which must not outlive the session it describes.
// sourcery: AutoMockable
nonisolated protocol SearchBackfillStoreProtocol: Sendable {
    /// Reads the cursor. Returns `nil` if absent or unreadable — never throws.
    func cursor() async -> SearchBackfillCursor?
    
    func save(_ cursor: SearchBackfillCursor) async
    
    func clear() async
}

/// Stores the backfill cursor as a JSON file in the session's data directory.
///
/// The session directory rather than user defaults, because every path that ends a session already
/// deletes that directory wholesale (`SessionDirectories.delete()`), so the cursor cannot outlive the
/// account it describes. A cursor that survived a logout would claim rooms were swept using the
/// previous account's room IDs.
final nonisolated class SearchBackfillStore: SearchBackfillStoreProtocol {
    private let fileURL: URL
    
    init(sessionDirectories: SessionDirectories) {
        // Must not start with `matrix-sdk-state` or `matrix-sdk-event-cache`: those prefixes are
        // what `SessionDirectories.deleteTransientUserData()` matches when clearing SDK stores.
        fileURL = sessionDirectories.dataDirectory.appending(component: "search-backfill-cursor.json")
    }
    
    // `@concurrent` because a nonisolated async function otherwise inherits its caller's
    // isolation, which would put this file I/O on the main actor.
    @concurrent
    func cursor() async -> SearchBackfillCursor? {
        guard FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) else {
            return nil
        }
        
        do {
            return try JSONDecoder().decode(SearchBackfillCursor.self, from: Data(contentsOf: fileURL))
        } catch {
            // A cursor we cannot read is treated as absent, not as an error: the sweep then starts a
            // fresh generation. Losing progress is cheap; failing a background task on a schema
            // change is not.
            MXLog.warning("Discarding unreadable search backfill cursor: \(error)")
            return nil
        }
    }
    
    @concurrent
    func save(_ cursor: SearchBackfillCursor) async {
        do {
            // Atomic because the NSE opens the same directory. Accessible after first unlock so the
            // background task can still read it while the device is locked.
            try JSONEncoder().encode(cursor).write(to: fileURL, options: [.atomic, .completeFileProtectionUntilFirstUserAuthentication])
        } catch {
            MXLog.error("Failed saving the search backfill cursor: \(error)")
        }
    }
    
    @concurrent
    func clear() async {
        do {
            if FileManager.default.fileExists(atPath: fileURL.path(percentEncoded: false)) {
                try FileManager.default.removeItem(at: fileURL)
            }
        } catch {
            MXLog.error("Failed clearing the search backfill cursor: \(error)")
        }
    }
}
