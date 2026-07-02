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
