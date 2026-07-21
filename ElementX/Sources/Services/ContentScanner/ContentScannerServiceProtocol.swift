//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ContentScannerServiceError: Error {
    case failedScanning
}

// sourcery: AutoMockable
/// Scans media sources through the content scanner, caching the verdicts by URL so that each source
/// is only ever scanned once. Mirrors ``MediaProviderProtocol``'s shape: a synchronous cache lookup
/// for views that already have a verdict and an async method to perform the scan.
nonisolated protocol ContentScannerServiceProtocol: Sendable {
    /// The cached scan verdict for the given source: `true` when the content is safe, `false` when
    /// it is unsafe, or `nil` when the source hasn't been scanned yet.
    func scanResultFromSource(_ source: MediaSourceProxy) -> Bool?
    
    /// Starts a scan for the given source unless there's already a cached verdict, in which case
    /// that is returned. Failed scans aren't cached so that they can be retried.
    @discardableResult
    func loadScanResultFromSource(_ source: MediaSourceProxy) async -> Result<Bool, ContentScannerServiceError>
}

nonisolated extension ContentScannerServiceProtocol {
    /// The combined cached verdict for several sources (e.g. a media source and its thumbnail, both
    /// downloaded through the scanner): `false` if any is unsafe, `true` if all are safe, or `nil`
    /// when any of them hasn't been scanned yet.
    func scanResultFromSources(_ sources: [MediaSourceProxy]) -> Bool? {
        let results = sources.map { scanResultFromSource($0) }
        if results.contains(false) {
            return false
        }
        if results.contains(where: { $0 == nil }) {
            return nil
        }
        return true
    }
    
    /// Scans several sources concurrently, resolving as soon as one comes back non-safe (unsafe or
    /// failed) since a single failure is enough to flag the media - the remaining scans are then
    /// ignored. Resolves as safe only when every source is safe.
    @discardableResult
    func loadScanResultFromSources(_ sources: [MediaSourceProxy]) async -> Result<Bool, ContentScannerServiceError> {
        await withTaskGroup(of: Result<Bool, ContentScannerServiceError>.self) { group in
            for source in sources {
                group.addTask { await loadScanResultFromSource(source) }
            }
            
            for await result in group where !result.isSafe {
                group.cancelAll()
                return result
            }
            
            return .success(true)
        }
    }
}

private nonisolated extension Result where Success == Bool {
    var isSafe: Bool {
        if case .success(true) = self {
            return true
        }
        return false
    }
}
