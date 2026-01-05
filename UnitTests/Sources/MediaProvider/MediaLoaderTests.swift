//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import XCTest

final class MediaLoaderTests: XCTestCase {
    func testMediaRequestCoalescing() async throws {
        let mediaLoadingClient = ClientSDKMock()
        mediaLoadingClient.getMediaContentMediaSourceReturnValue = Data()
        let mediaLoader = MediaLoader(client: mediaLoadingClient)
        
        let mediaSource = try MediaSourceProxy(url: .mockMXCFile, mimeType: nil)
        
        do {
            for _ in 1...10 {
                _ = try await mediaLoader.loadMediaContentForSource(mediaSource)
            }
            
            XCTAssertEqual(mediaLoadingClient.getMediaContentMediaSourceCallsCount, 10)
        } catch {
            fatalError()
        }
    }
    
    func testMediaThumbnailRequestCoalescing() async throws {
        let mediaLoadingClient = ClientSDKMock()
        mediaLoadingClient.getMediaThumbnailMediaSourceWidthHeightReturnValue = Data()
        let mediaLoader = MediaLoader(client: mediaLoadingClient)
        
        let mediaSource = try MediaSourceProxy(url: .mockMXCImage, mimeType: nil)
        
        do {
            for _ in 1...10 {
                _ = try await mediaLoader.loadMediaThumbnailForSource(mediaSource, width: 100, height: 100)
            }
            
            XCTAssertEqual(mediaLoadingClient.getMediaThumbnailMediaSourceWidthHeightCallsCount, 10)
        } catch {
            fatalError()
        }
    }
}
