//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX

import Combine
import Kingfisher
import XCTest

@MainActor
final class MediaProviderTests: XCTestCase {
    private var mediaLoader: MediaLoaderMock!
    private var imageCache: MockImageCache!
    private var networkMonitor: NetworkMonitorMock!
    
    var mediaProvider: MediaProvider!
    
    override func setUp() {
        mediaLoader = MediaLoaderMock()
        imageCache = MockImageCache(name: "Test")
        networkMonitor = NetworkMonitorMock()
        
        mediaProvider = MediaProvider(mediaLoader: mediaLoader,
                                      imageCache: imageCache,
                                      networkMonitor: networkMonitor)
    }
    
    func testLoadingRetriedOnReconnection() async throws {
        let testImage = try loadTestImage()
        guard let pngData = testImage.pngData() else {
            XCTFail("Test image should contain valid .png data")
            return
        }
        
        let loadTask = try mediaProvider.loadImageRetryingOnReconnection(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"))
        
        let connectivitySubject = CurrentValueSubject<NetworkMonitorReachability, Never>(.unreachable)
        
        mediaLoader.loadMediaContentForSourceClosure = { _ in
            switch connectivitySubject.value {
            case .unreachable:
                connectivitySubject.send(.reachable)
                throw MediaProviderTestsError.error
            case .reachable:
                return pngData
            }
        }
        
        networkMonitor.underlyingReachabilityPublisher = connectivitySubject.asCurrentValuePublisher()
        
        let result = try? await loadTask.value
        
        XCTAssertNotNil(result)
        XCTAssertEqual(mediaLoader.loadMediaContentForSourceCallsCount, 2)
    }
    
    func testLoadingRetriedOnReconnectionCancelsAfterSecondFailure() async throws {
        let loadTask = try mediaProvider.loadImageRetryingOnReconnection(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"))
        
        let connectivitySubject = CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable)
        
        mediaLoader.loadMediaContentForSourceThrowableError = MediaProviderTestsError.error
        
        networkMonitor.underlyingReachabilityPublisher = connectivitySubject.asCurrentValuePublisher()
        
        let result = try? await loadTask.value
        
        XCTAssertNil(result)
    }
    
    func test_whenImageFromSourceWithSourceNil_nilReturned() throws {
        let image = try mediaProvider.imageFromSource(nil, size: Avatars.Size.room(on: .timeline).scaledSize)
        XCTAssertNil(image)
    }
    
    func test_whenImageFromSourceWithSourceNotNilAndImageCacheContainsImage_ImageIsReturned() throws {
        let avatarSize = Avatars.Size.room(on: .timeline)
        let url = URL.mockMXCImage
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImagesInMemory[key] = imageForKey
        let image = try mediaProvider.imageFromSource(MediaSourceProxy(url: url, mimeType: "image/jpeg"),
                                                      size: avatarSize.scaledSize)
        XCTAssertEqual(image, imageForKey)
    }
    
    func test_whenImageFromSourceWithSourceNotNilAndImageNotCached_nilReturned() throws {
        let image = try mediaProvider.imageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                      size: Avatars.Size.room(on: .timeline).scaledSize)
        XCTAssertNil(image)
    }
    
    func test_whenLoadImageFromSourceAndImageCacheContainsImage_successIsReturned() async throws {
        let avatarSize = Avatars.Size.room(on: .timeline)
        let url = URL.mockMXCImage
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImagesInMemory[key] = imageForKey
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: url, mimeType: "image/jpeg"),
                                                                 size: avatarSize.scaledSize)
        XCTAssertEqual(Result.success(imageForKey), result)
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageSucceeds_successIsReturned() async throws {
        let avatarSize = Avatars.Size.room(on: .timeline)
        let url = URL.mockMXCImage
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImages[key] = imageForKey
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: url, mimeType: "image/jpeg"),
                                                                 size: avatarSize.scaledSize)
        XCTAssertEqual(Result.success(imageForKey), result)
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFails_imageThumbnailIsLoaded() async throws {
        let avatarSize = Avatars.Size.room(on: .timeline)
        let expectedImage = try loadTestImage()
        
        mediaLoader.loadMediaThumbnailForSourceWidthHeightReturnValue = expectedImage.pngData()
        
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                                 size: avatarSize.scaledSize)
        switch result {
        case .success(let image):
            XCTAssertEqual(image.pngData(), expectedImage.pngData())
        case .failure:
            XCTFail("Should be success")
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFails_imageIsStored() async throws {
        let avatarSize = Avatars.Size.room(on: .timeline)
        let url = URL.mockMXCImage
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let expectedImage = try loadTestImage()

        mediaLoader.loadMediaThumbnailForSourceWidthHeightReturnValue = expectedImage.pngData()
        
        _ = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: url, mimeType: "image/jpeg"),
                                                        size: avatarSize.scaledSize)
        let storedImage = try XCTUnwrap(imageCache.storedImages[key])
        XCTAssertEqual(expectedImage.pngData(), storedImage.pngData())
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndNoAvatarSize_imageContentIsLoaded() async throws {
        let expectedImage = try loadTestImage()

        mediaLoader.loadMediaContentForSourceReturnValue = expectedImage.pngData()
        
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                                 size: nil)
        switch result {
        case .success(let image):
            XCTAssertEqual(image.pngData(), expectedImage.pngData())
        case .failure:
            XCTFail("Should be success")
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndLoadImageThumbnailFails_errorIsThrown() async throws {
        mediaLoader.loadMediaThumbnailForSourceWidthHeightThrowableError = MediaProviderTestsError.error
        
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                                 size: Avatars.Size.room(on: .timeline).scaledSize)
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.failedRetrievingImage)
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndNoAvatarSizeAndLoadImageContentFails_errorIsThrown() async throws {
        mediaLoader.loadMediaContentForSourceThrowableError = MediaProviderTestsError.error
        
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                                 size: nil)
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.failedRetrievingImage)
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndImageThumbnailIsLoadedWithCorruptedData_errorIsThrown() async throws {
        mediaLoader.loadMediaThumbnailForSourceWidthHeightReturnValue = Data()
        
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                                 size: Avatars.Size.room(on: .timeline).scaledSize)
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.invalidImageData)
        }
    }
    
    private func loadTestImage() throws -> UIImage {
        guard let path = Bundle(for: Self.self).path(forResource: "test_image", ofType: "png"),
              let image = UIImage(contentsOfFile: path) else {
            throw MediaProviderTestsError.error
        }
        return image
    }
}

private enum MediaProviderTestsError: Error {
    case error
}
