//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
struct URLTests {
    @Test
    func urlDirectoryName() throws {
        let url: URL = "https://matrix.example.com/foo/bar/"
        let directoryName = url.asDirectoryName()
        #expect(directoryName == "matrix.example.com-foo-bar")
        try createDirectory(with: directoryName)
    }
    
    @Test
    func complexURLDirectoryName() throws {
        let url: URL = "https://us%3Aer:pa%40%3Ass@[2001:db8:85a3::8a2e:370:7334]:8443/..//folder/./fi%20le(1).html;p=1;q=2"
        let directoryName = url.asDirectoryName()
        #expect(directoryName == "us%3Aer-pa%40%3Ass@[2001-db8-85a3--8a2e-370-7334]-8443-..--folder-.-fi%20le(1).html;p=1;q=2")
        try createDirectory(with: directoryName)
    }
    
    // MARK: - Helpers
    
    func createDirectory(with directoryName: String) throws {
        let url = URL.temporaryDirectory.appending(path: directoryName)
        try? FileManager.default.removeItem(at: url)
        
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
        
        guard FileManager.default.directoryExists(at: url) else {
            Issue.record("Invalid file path")
            return
        }
    }
}
