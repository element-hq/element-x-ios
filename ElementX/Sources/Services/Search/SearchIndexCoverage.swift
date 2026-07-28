//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Keeps the local search index honest about how much history it can actually see.
///
/// The SDK indexes events as they pass through the event cache, and only from the moment the index is
/// attached. Back-paginating history that is already in the on-disk event cache re-hydrates it from
/// there, and those updates are deliberately not broadcast, so nothing indexes them. Any session whose
/// cache was populated before its index existed therefore carries a band of history that no amount of
/// paginating will ever make searchable — and nothing reports it.
///
/// The repair is blunt and one-off: delete the event cache store so that history re-enters over the
/// network, the one path the indexer does observe. A marker file records that coverage holds, so a
/// session is never charged for it twice.
nonisolated struct SearchIndexCoverage {
    private let sessionDirectories: SessionDirectories
    private let backfillStore: SearchBackfillStoreProtocol
    
    init(sessionDirectories: SessionDirectories, backfillStore: SearchBackfillStoreProtocol) {
        self.sessionDirectories = sessionDirectories
        self.backfillStore = backfillStore
    }
    
    init(sessionDirectories: SessionDirectories) {
        self.init(sessionDirectories: sessionDirectories,
                  backfillStore: SearchBackfillStore(sessionDirectories: sessionDirectories))
    }
    
    /// Records that a session built with its index already attached is covered by construction: nothing
    /// can reach its event cache without the indexer seeing it arrive.
    ///
    /// Without this, the session's *next* launch would find no marker beside a populated cache and heal
    /// a session that never needed it.
    @concurrent
    func markCoveredByConstruction() async {
        writeMarker()
    }
    
    /// Brings a session that is about to be restored from disk back into coverage.
    ///
    /// Must run before the client is built: it deletes files the SDK would otherwise be holding open.
    ///
    /// - Parameter isHealEnabled: when `false` only the non-destructive outcomes are applied, leaving an
    ///   uncovered session for a later launch to repair. Enabling it afterwards stays correct, because
    ///   the sessions skipped here are exactly the ones that still need the repair.
    @concurrent
    func restoreCoverage(isHealEnabled: Bool) async {
        guard !sessionDirectories.hasSearchIndexCoverageMarker else { return }
        
        guard sessionDirectories.hasEventCacheStore else {
            // Nothing is cached yet, so the index starts level with the cache.
            writeMarker()
            return
        }
        
        guard isHealEnabled else {
            MXLog.info("Search index coverage is unproven but the repair is disabled")
            return
        }
        
        do {
            try sessionDirectories.deleteEventCacheData()
        } catch {
            // Deliberately no marker: the next launch tries again. A marker over a failed deletion
            // would claim coverage that doesn't exist, and nothing would ever revisit it.
            MXLog.error("Failed deleting the event cache store to restore search index coverage: \(error)")
            return
        }
        
        // The backfill sweep records the rooms it has visited. Those visits walked the history just
        // deleted, so they indexed nothing — dropping the cursor makes the next sweep revisit them
        // rather than wait for the current generation to drain.
        await backfillStore.clear()
        
        MXLog.info("Deleted the event cache store to restore search index coverage")
        
        writeMarker()
    }
    
    // MARK: - Private
    
    private func writeMarker() {
        do {
            try sessionDirectories.writeSearchIndexCoverageMarker()
        } catch {
            // Only ever costs a repeat of the check on the next launch, which is the safe direction.
            MXLog.error("Failed writing the search index coverage marker: \(error)")
        }
    }
}
