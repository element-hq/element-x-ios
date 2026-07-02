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
}

extension ContentScannerServiceMock {
    convenience init(_ configuration: ContentScannerServiceMockConfiguration) {
        self.init()
        
        scanResultFromSourceReturnValue = configuration.scanResult
        loadScanResultFromSourceClosure = { _ in
            guard let scanResult = configuration.scanResult else {
                try? await Task.sleep(for: .seconds(3600))
                return .failure(.failedScanning)
            }
            return .success(scanResult)
        }
    }
}
