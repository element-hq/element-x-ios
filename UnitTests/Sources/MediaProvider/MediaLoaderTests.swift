//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import XCTest

final class MediaLoaderTests: XCTestCase {
    func testMediaRequestCoalescing() async {
        let mediaLoadingClient = ClientSDKMock()
        mediaLoadingClient.getMediaContentMediaSourceReturnValue = Data()
        let mediaLoader = MediaLoader(client: mediaLoadingClient)
        
        let mediaSource = MediaSourceProxy(url: URL.documentsDirectory, mimeType: nil)
        
        do {
            for _ in 1...10 {
                _ = try await mediaLoader.loadMediaContentForSource(mediaSource)
            }
            
            XCTAssertEqual(mediaLoadingClient.getMediaContentMediaSourceCallsCount, 10)
        } catch {
            fatalError()
        }
    }
    
    func testMediaThumbnailRequestCoalescing() async {
        let mediaLoadingClient = ClientSDKMock()
        mediaLoadingClient.getMediaThumbnailMediaSourceWidthHeightReturnValue = Data()
        let mediaLoader = MediaLoader(client: mediaLoadingClient)
        
        let mediaSource = MediaSourceProxy(url: URL.documentsDirectory, mimeType: nil)
        
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
