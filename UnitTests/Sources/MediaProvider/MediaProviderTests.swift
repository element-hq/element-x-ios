//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Kingfisher
import Testing

@MainActor
@Suite
struct MediaProviderTests {
    private var mediaLoader: MediaLoaderMock!
    private var imageCache: MockImageCache!
    private var reachabilitySubject = CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable)
    
    var mediaProvider: MediaProvider!
    
    init() {
        mediaLoader = MediaLoaderMock()
        imageCache = MockImageCache(name: "Test")
        
        mediaProvider = MediaProvider(mediaLoader: mediaLoader,
                                      imageCache: imageCache,
                                      homeserverReachabilityPublisher: reachabilitySubject.asCurrentValuePublisher())
    }
    
    @Test
    mutating func loadingRetriedOnReconnection() async throws {
        let testImage = try loadTestImage()
        guard let pngData = testImage.pngData() else {
            Issue.record("Test image should contain valid .png data")
            return
        }
        
        let loadTask = try mediaProvider.loadImageRetryingOnReconnection(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"))
        
        reachabilitySubject.send(.unreachable)
        
        mediaLoader.loadMediaContentForSourceClosure = { [reachabilitySubject] _ in
            switch reachabilitySubject.value {
            case .unreachable:
                reachabilitySubject.send(.reachable)
                throw MediaProviderTestsError.error
            case .reachable:
                return pngData
            }
        }
        
        let result = try? await loadTask.value
        
        #expect(result != nil)
        #expect(mediaLoader.loadMediaContentForSourceCallsCount == 2)
    }
    
    @Test
    mutating func loadingRetriedOnReconnectionCancelsAfterSecondFailure() async throws {
        let loadTask = try mediaProvider.loadImageRetryingOnReconnection(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"))
        
        reachabilitySubject.send(.reachable)
        
        mediaLoader.loadMediaContentForSourceThrowableError = MediaProviderTestsError.error
        
        let result = try? await loadTask.value
        
        #expect(result == nil)
    }
    
    @Test
    func whenImageFromSourceWithSourceNil_nilReturned() {
        let image = mediaProvider.imageFromSource(nil, size: Avatars.Size.room(on: .timeline).scaledSize)
        #expect(image == nil)
    }
    
    @Test
    func whenImageFromSourceWithSourceNotNilAndImageCacheContainsImage_ImageIsReturned() throws {
        let avatarSize = Avatars.Size.room(on: .timeline)
        let url = URL.mockMXCImage
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImagesInMemory[key] = imageForKey
        let image = try mediaProvider.imageFromSource(MediaSourceProxy(url: url, mimeType: "image/jpeg"),
                                                      size: avatarSize.scaledSize)
        #expect(image == imageForKey)
    }
    
    @Test
    func whenImageFromSourceWithSourceNotNilAndImageNotCached_nilReturned() throws {
        let image = try mediaProvider.imageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                      size: Avatars.Size.room(on: .timeline).scaledSize)
        #expect(image == nil)
    }
    
    @Test
    func whenLoadImageFromSourceAndImageCacheContainsImage_successIsReturned() async throws {
        let avatarSize = Avatars.Size.room(on: .timeline)
        let url = URL.mockMXCImage
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImagesInMemory[key] = imageForKey
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: url, mimeType: "image/jpeg"),
                                                                 size: avatarSize.scaledSize)
        #expect(Result.success(imageForKey) == result)
    }
    
    @Test
    func whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageSucceeds_successIsReturned() async throws {
        let avatarSize = Avatars.Size.room(on: .timeline)
        let url = URL.mockMXCImage
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImages[key] = imageForKey
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: url, mimeType: "image/jpeg"),
                                                                 size: avatarSize.scaledSize)
        #expect(Result.success(imageForKey) == result)
    }
    
    @Test
    mutating func whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFails_imageThumbnailIsLoaded() async throws {
        let avatarSize = Avatars.Size.room(on: .timeline)
        let expectedImage = try loadTestImage()
        
        mediaLoader.loadMediaThumbnailForSourceWidthHeightReturnValue = expectedImage.pngData()
        
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                                 size: avatarSize.scaledSize)
        switch result {
        case .success(let image):
            #expect(image.pngData() == expectedImage.pngData())
        case .failure:
            Issue.record("Should be success")
        }
    }
    
    @Test
    mutating func whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFails_imageIsStored() async throws {
        let avatarSize = Avatars.Size.room(on: .timeline)
        let url = URL.mockMXCImage
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let expectedImage = try loadTestImage()

        mediaLoader.loadMediaThumbnailForSourceWidthHeightReturnValue = expectedImage.pngData()
        
        _ = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: url, mimeType: "image/jpeg"),
                                                        size: avatarSize.scaledSize)
        let storedImage = try #require(imageCache.storedImages[key])
        #expect(expectedImage.pngData() == storedImage.pngData())
    }
    
    @Test
    mutating func whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndNoAvatarSize_imageContentIsLoaded() async throws {
        let expectedImage = try loadTestImage()

        mediaLoader.loadMediaContentForSourceReturnValue = expectedImage.pngData()
        
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                                 size: nil)
        switch result {
        case .success(let image):
            #expect(image.pngData() == expectedImage.pngData())
        case .failure:
            Issue.record("Should be success")
        }
    }
    
    @Test
    mutating func whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndLoadImageThumbnailFails_errorIsThrown() async throws {
        mediaLoader.loadMediaThumbnailForSourceWidthHeightThrowableError = MediaProviderTestsError.error
        
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                                 size: Avatars.Size.room(on: .timeline).scaledSize)
        switch result {
        case .success:
            Issue.record("Should fail")
        case .failure(let error):
            #expect(error == MediaProviderError.failedRetrievingImage)
        }
    }
    
    @Test
    mutating func whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndNoAvatarSizeAndLoadImageContentFails_errorIsThrown() async throws {
        mediaLoader.loadMediaContentForSourceThrowableError = MediaProviderTestsError.error
        
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                                 size: nil)
        switch result {
        case .success:
            Issue.record("Should fail")
        case .failure(let error):
            #expect(error == MediaProviderError.failedRetrievingImage)
        }
    }
    
    @Test
    mutating func whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndImageThumbnailIsLoadedWithCorruptedData_errorIsThrown() async throws {
        mediaLoader.loadMediaThumbnailForSourceWidthHeightReturnValue = Data()
        
        let result = try await mediaProvider.loadImageFromSource(MediaSourceProxy(url: .mockMXCImage, mimeType: "image/jpeg"),
                                                                 size: Avatars.Size.room(on: .timeline).scaledSize)
        switch result {
        case .success:
            Issue.record("Should fail")
        case .failure(let error):
            #expect(error == MediaProviderError.invalidImageData)
        }
    }
    
    private func loadTestImage() throws -> UIImage {
        guard let path = Bundle(for: BundleFinder.self).path(forResource: "test_image", ofType: "png"),
              let image = UIImage(contentsOfFile: path) else {
            throw MediaProviderTestsError.error
        }
        return image
    }
}

private class BundleFinder {}

private enum MediaProviderTestsError: Error {
    case error
}
