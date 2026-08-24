//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation

extension SessionDirectories {
    var mockStateStorePath: String {
        dataDirectory.appending(component: "matrix-sdk-state.sqlite3").path(percentEncoded: false)
    }
    
    var mockCryptoStorePath: String {
        dataDirectory.appending(component: "matrix-sdk-crypto.sqlite3").path(percentEncoded: false)
    }
    
    var mockEventCachePath: String {
        cacheDirectory.appending(component: "matrix-sdk-event-cache.sqlite3").path(percentEncoded: false)
    }
    
    func generateMockData() {
        generateMockDatabase(atPath: mockStateStorePath)
        generateMockDatabase(atPath: mockCryptoStorePath)
        generateMockDatabase(atPath: mockEventCachePath)
    }
    
    private func generateMockDatabase(atPath path: String) {
        FileManager.default.createFile(atPath: path, contents: nil)
        FileManager.default.createFile(atPath: path + "-shm", contents: nil)
        FileManager.default.createFile(atPath: path + "-wal", contents: nil)
    }
}
