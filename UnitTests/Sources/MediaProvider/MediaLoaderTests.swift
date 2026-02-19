//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks
import Testing

@Suite
struct MediaLoaderTests {
    @Test
    func mediaRequestCoalescing() async throws {
        let mediaLoadingClient = ClientSDKMock()
        mediaLoadingClient.getMediaContentMediaSourceReturnValue = Data()
        let mediaLoader = MediaLoader(client: mediaLoadingClient)
        
        let mediaSource = try MediaSourceProxy(url: .mockMXCFile, mimeType: nil)
        
        for _ in 1...10 {
            _ = try await mediaLoader.loadMediaContentForSource(mediaSource)
        }
        
        #expect(mediaLoadingClient.getMediaContentMediaSourceCallsCount == 10)
    }
    
    @Test
    func mediaThumbnailRequestCoalescing() async throws {
        let mediaLoadingClient = ClientSDKMock()
        mediaLoadingClient.getMediaThumbnailMediaSourceWidthHeightReturnValue = Data()
        let mediaLoader = MediaLoader(client: mediaLoadingClient)
        
        let mediaSource = try MediaSourceProxy(url: .mockMXCImage, mimeType: nil)
        
        for _ in 1...10 {
            _ = try await mediaLoader.loadMediaThumbnailForSource(mediaSource, width: 100, height: 100)
        }
        
        #expect(mediaLoadingClient.getMediaThumbnailMediaSourceWidthHeightCallsCount == 10)
    }
}
