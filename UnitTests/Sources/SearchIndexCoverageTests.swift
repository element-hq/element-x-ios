//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct SearchIndexCoverageTests {
    let fileManager = FileManager.default
    
    @Test
    func freshSessionIsCoveredByConstruction() async throws {
        // Given a session that has just been built with its index attached.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        sessionDirectories.generateMockData()
        
        // When recording that.
        await SearchIndexCoverage(sessionDirectories: sessionDirectories,
                                  backfillStore: SearchBackfillStoreMock()).markCoveredByConstruction()
        
        // Then the marker should be written without touching a thing, so that the next launch doesn't
        // repair a session that was never broken.
        #expect(sessionDirectories.hasSearchIndexCoverageMarker)
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockEventCachePath))
        
        sessionDirectories.delete()
    }
    
    @Test
    func uncoveredSessionIsRepaired() async throws {
        // Given a restored session holding cached history that its index can't be shown to have seen.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        sessionDirectories.generateMockData()
        let backfillStore = SearchBackfillStoreMock()
        
        // When restoring coverage.
        await SearchIndexCoverage(sessionDirectories: sessionDirectories,
                                  backfillStore: backfillStore).restoreCoverage(isHealEnabled: true)
        
        // Then the event cache and its sidecars should be gone and the marker written.
        #expect(try fileManager.numberOfItems(at: sessionDirectories.cacheDirectory) == 0)
        #expect(sessionDirectories.hasSearchIndexCoverageMarker)
        
        // And the backfill cursor should be dropped, as the rooms it recorded as swept were swept
        // against the history that has just been deleted.
        #expect(backfillStore.clearCallsCount == 1)
        
        // And nothing else should have been deleted.
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockStateStorePath))
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockCryptoStorePath))
        
        sessionDirectories.delete()
    }
    
    @Test
    func coveredSessionIsLeftAlone() async throws {
        // Given a session that is already recorded as covered.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        sessionDirectories.generateMockData()
        try sessionDirectories.writeSearchIndexCoverageMarker()
        let backfillStore = SearchBackfillStoreMock()
        
        // When restoring coverage.
        await SearchIndexCoverage(sessionDirectories: sessionDirectories,
                                  backfillStore: backfillStore).restoreCoverage(isHealEnabled: true)
        
        // Then nothing should happen — this is what makes the repair a one-off.
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockEventCachePath))
        #expect(backfillStore.clearCallsCount == 0)
        
        sessionDirectories.delete()
    }
    
    @Test
    func sessionWithoutAnEventCacheIsMarkedWithoutDeletingAnything() async throws {
        // Given a session that has never cached anything.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        let backfillStore = SearchBackfillStoreMock()
        
        // When restoring coverage.
        await SearchIndexCoverage(sessionDirectories: sessionDirectories,
                                  backfillStore: backfillStore).restoreCoverage(isHealEnabled: true)
        
        // Then it should be marked as covered: the index starts level with the cache.
        #expect(sessionDirectories.hasSearchIndexCoverageMarker)
        #expect(backfillStore.clearCallsCount == 0)
        
        sessionDirectories.delete()
    }
    
    @Test
    func repairIsSkippedWhenDisabled() async throws {
        // Given an uncovered session and a disabled repair.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        sessionDirectories.generateMockData()
        let backfillStore = SearchBackfillStoreMock()
        
        // When restoring coverage.
        await SearchIndexCoverage(sessionDirectories: sessionDirectories,
                                  backfillStore: backfillStore).restoreCoverage(isHealEnabled: false)
        
        // Then nothing should be deleted, and crucially no marker written: enabling the repair later
        // has to still find the sessions that need it.
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockEventCachePath))
        #expect(!sessionDirectories.hasSearchIndexCoverageMarker)
        #expect(backfillStore.clearCallsCount == 0)
        
        sessionDirectories.delete()
    }
    
    @Test
    func markerIsNotWrittenWhenTheDeletionFails() async throws {
        // Given an uncovered session whose caches directory can't be written to.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        sessionDirectories.generateMockData()
        let backfillStore = SearchBackfillStoreMock()
        try fileManager.setAttributes([.posixPermissions: 0o500], ofItemAtPath: sessionDirectories.cachePath)
        
        // When restoring coverage.
        await SearchIndexCoverage(sessionDirectories: sessionDirectories,
                                  backfillStore: backfillStore).restoreCoverage(isHealEnabled: true)
        
        // Then the session should be left uncovered so the next launch tries again. A marker written
        // over a failed deletion would claim coverage that doesn't exist, and nothing would revisit it.
        #expect(!sessionDirectories.hasSearchIndexCoverageMarker)
        #expect(backfillStore.clearCallsCount == 0)
        
        try fileManager.setAttributes([.posixPermissions: 0o700], ofItemAtPath: sessionDirectories.cachePath)
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockEventCachePath))
        
        sessionDirectories.delete()
    }
    
    @Test
    func interruptedRepairIsFinished() async throws {
        // Given a session where an earlier repair died after the sidecars-first loop had deleted the
        // database but not its sidecars.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        sessionDirectories.generateMockData()
        try fileManager.removeItem(atPath: sessionDirectories.mockEventCachePath)
        let backfillStore = SearchBackfillStoreMock()
        
        // When restoring coverage.
        await SearchIndexCoverage(sessionDirectories: sessionDirectories,
                                  backfillStore: backfillStore).restoreCoverage(isHealEnabled: true)
        
        // Then the orphaned sidecars should be swept rather than mistaken for a session with nothing
        // to repair, which would mark it as covered while it still held unindexed history.
        #expect(try fileManager.numberOfItems(at: sessionDirectories.cacheDirectory) == 0)
        #expect(backfillStore.clearCallsCount == 1)
        #expect(sessionDirectories.hasSearchIndexCoverageMarker)
        
        sessionDirectories.delete()
    }
    
    @Test
    func repairRunsOnlyOnce() async throws {
        // Given a session that has already been repaired.
        let sessionDirectories = try SessionDirectories.makeForTesting()
        sessionDirectories.generateMockData()
        let backfillStore = SearchBackfillStoreMock()
        let coverage = SearchIndexCoverage(sessionDirectories: sessionDirectories, backfillStore: backfillStore)
        await coverage.restoreCoverage(isHealEnabled: true)
        
        // When the app is launched again and the cache has refilled over the network.
        sessionDirectories.generateMockData()
        await coverage.restoreCoverage(isHealEnabled: true)
        
        // Then the freshly indexed history should survive.
        #expect(fileManager.fileExists(atPath: sessionDirectories.mockEventCachePath))
        #expect(backfillStore.clearCallsCount == 1)
        
        sessionDirectories.delete()
    }
}
