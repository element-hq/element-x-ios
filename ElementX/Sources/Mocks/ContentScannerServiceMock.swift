//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct ContentScannerServiceMockConfiguration {
    /// The verdict reported for every source: `true` when safe, `false` when unsafe, or `nil` to
    /// never resolve the scan so that the scanning state remains visible.
    var scanResult: Bool?
    /// Overrides `scanResult` on a per-source basis, using the same `true`/`false`/`nil` semantics.
    var perSourceScanResult: (@Sendable (MediaSourceProxy) -> Bool?)?
}

extension ContentScannerServiceMock {
    convenience init(_ configuration: ContentScannerServiceMockConfiguration) {
        self.init()
        
        let blanketScanResult = configuration.scanResult
        let resolve: @Sendable (MediaSourceProxy) -> Bool? = configuration.perSourceScanResult ?? { _ in blanketScanResult }
        
        scanResultFromSourceClosure = { resolve($0) }
        loadScanResultFromSourceClosure = { source in
            guard let scanResult = resolve(source) else {
                try? await Task.sleep(for: .seconds(3600))
                return .failure(.failedScanning)
            }
            return .success(scanResult)
        }
    }
}
