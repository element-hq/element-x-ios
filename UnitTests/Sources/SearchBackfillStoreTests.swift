//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@MainActor
struct SearchBackfillStoreTests {
    @Test
    func aCursorRoundTripsThroughDisk() async {
        let directories = makeSessionDirectories()
        defer { try? FileManager.default.removeItem(at: directories.dataDirectory) }
        
        let cursor = SearchBackfillCursor(generation: 2,
                                          queue: ["!a:server", "!b:server"],
                                          index: 1,
                                          pagesDone: ["!a:server": 7],
                                          failures: ["!a:server": 1],
                                          outcomes: ["!a:server": .reachedStart],
                                          pagesIssued: 7,
                                          startedAt: Date(timeIntervalSinceReferenceDate: 1000),
                                          stoppedByBudget: true)
        
        await SearchBackfillStore(sessionDirectories: directories).save(cursor)
        
        // A fresh instance, so this reads the file rather than anything held in memory.
        #expect(await SearchBackfillStore(sessionDirectories: directories).cursor() == cursor)
    }
    
    @Test
    func anAbsentCursorReadsAsNil() async {
        let directories = makeSessionDirectories()
        defer { try? FileManager.default.removeItem(at: directories.dataDirectory) }
        
        #expect(await SearchBackfillStore(sessionDirectories: directories).cursor() == nil)
    }
    
    @Test
    func anUnreadableCursorIsDiscardedRatherThanThrowing() async throws {
        // Losing progress is cheap; failing a background task on a schema change is not.
        let directories = makeSessionDirectories()
        defer { try? FileManager.default.removeItem(at: directories.dataDirectory) }
        
        let store = SearchBackfillStore(sessionDirectories: directories)
        await store.save(.init(generation: 1))
        try Data("not json".utf8).write(to: directories.dataDirectory.appending(component: "search-backfill-cursor.json"))
        
        #expect(await store.cursor() == nil)
    }
    
    @Test
    func clearingRemovesTheCursor() async {
        let directories = makeSessionDirectories()
        defer { try? FileManager.default.removeItem(at: directories.dataDirectory) }
        
        let store = SearchBackfillStore(sessionDirectories: directories)
        await store.save(.init(generation: 1))
        await store.clear()
        
        #expect(await store.cursor() == nil)
        // Clearing twice must not throw either — the background task has no one to report to.
        await store.clear()
    }
    
    @Test
    func theCursorFilenameCannotCollideWithTheSDKStores() async throws {
        // `deleteTransientUserData()` clears the SDK's stores by PREFIX-matching file names, so a
        // cursor named with either prefix would be wiped whenever the caches are cleared.
        let directories = makeSessionDirectories()
        defer { try? FileManager.default.removeItem(at: directories.dataDirectory) }
        
        await SearchBackfillStore(sessionDirectories: directories).save(.init(generation: 3))
        
        let written = try FileManager.default.contentsOfDirectory(at: directories.dataDirectory, includingPropertiesForKeys: nil)
        let names = written.map(\.lastPathComponent)
        #expect(names.count == 1)
        #expect(names.allSatisfy { !$0.hasPrefix("matrix-sdk-state") && !$0.hasPrefix("matrix-sdk-event-cache") })
    }
    
    // MARK: - Helpers
    
    private func makeSessionDirectories() -> SessionDirectories {
        // A temporary directory, because the no-argument initialiser writes into the real app group
        // container.
        let dataDirectory = URL.temporaryDirectory.appending(component: UUID().uuidString)
        try? FileManager.default.createDirectory(at: dataDirectory, withIntermediateDirectories: true)
        return SessionDirectories(dataDirectory: dataDirectory)
    }
}
