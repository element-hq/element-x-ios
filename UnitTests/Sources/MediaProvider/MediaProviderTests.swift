//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

@testable import ElementX
import Kingfisher
import XCTest

@MainActor
final class MediaProviderTests: XCTestCase {
    private let mediaLoader = MockMediaLoader()
    private var imageCache: MockImageCache!
    private var backgroundTaskService = MockBackgroundTaskService()
    
    var mediaProvider: MediaProvider!
    
    override func setUp() {
        imageCache = MockImageCache(name: "Test")
        mediaProvider = MediaProvider(mediaLoader: mediaLoader,
                                      imageCache: imageCache,
                                      backgroundTaskService: backgroundTaskService)
    }
    
    func test_whenImageFromSourceWithSourceNil_nilReturned() throws {
        let image = mediaProvider.imageFromSource(nil, size: AvatarSize.room(on: .timeline).scaledSize)
        XCTAssertNil(image)
    }
    
    func test_whenImageFromSourceWithSourceNotNilAndImageCacheContainsImage_ImageIsReturned() throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let url = URL.picturesDirectory
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImagesInMemory[key] = imageForKey
        let image = mediaProvider.imageFromSource(MediaSourceProxy(url: url), size: avatarSize.scaledSize)
        XCTAssertEqual(image, imageForKey)
    }
    
    func test_whenImageFromSourceWithSourceNotNilAndImageNotCached_nilReturned() throws {
        let image = mediaProvider.imageFromSource(MediaSourceProxy(url: URL.picturesDirectory),
                                                  size: AvatarSize.room(on: .timeline).scaledSize)
        XCTAssertNil(image)
    }
    
    func test_whenLoadImageFromSourceAndImageCacheContainsImage_successIsReturned() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let url = URL.picturesDirectory
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImagesInMemory[key] = imageForKey
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(url: url), size: avatarSize.scaledSize)
        XCTAssertEqual(Result.success(imageForKey), result)
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageSucceeds_successIsReturned() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let url = URL.picturesDirectory
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImages[key] = imageForKey
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(url: url), size: avatarSize.scaledSize)
        XCTAssertEqual(Result.success(imageForKey), result)
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFails_imageThumbnailIsLoaded() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let expectedImage = try loadTestImage()
        mediaLoader.mediaThumbnailData = expectedImage.pngData()
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(url: URL.picturesDirectory), size: avatarSize.scaledSize)
        switch result {
        case .success(let image):
            XCTAssertEqual(image.pngData(), expectedImage.pngData())
        case .failure:
            XCTFail("Should be success")
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFails_imageIsStored() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let url = URL.picturesDirectory
        let key = "\(url.absoluteString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let expectedImage = try loadTestImage()
        mediaLoader.mediaThumbnailData = expectedImage.pngData()
        _ = await mediaProvider.loadImageFromSource(MediaSourceProxy(url: url), size: avatarSize.scaledSize)
        let storedImage = try XCTUnwrap(imageCache.storedImages[key])
        XCTAssertEqual(expectedImage.pngData(), storedImage.pngData())
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndNoAvatarSize_imageContentIsLoaded() async throws {
        let expectedImage = try loadTestImage()
        mediaLoader.mediaContentData = expectedImage.pngData()
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(url: URL.picturesDirectory), size: nil)
        switch result {
        case .success(let image):
            XCTAssertEqual(image.pngData(), expectedImage.pngData())
        case .failure:
            XCTFail("Should be success")
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndLoadImageThumbnailFails_errorIsThrown() async throws {
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(url: URL.picturesDirectory),
                                                             size: AvatarSize.room(on: .timeline).scaledSize)
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.failedRetrievingImage)
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndNoAvatarSizeAndLoadImageContentFails_errorIsThrown() async throws {
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(url: URL.picturesDirectory), size: nil)
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.failedRetrievingImage)
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndImageThumbnailIsLoadedWithCorruptedData_errorIsThrown() async throws {
        mediaLoader.mediaThumbnailData = Data()
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(url: URL.picturesDirectory),
                                                             size: AvatarSize.room(on: .timeline).scaledSize)
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.invalidImageData)
        }
    }
    
    func test_whenLoadFileFromSourceAndFileFromSourceExists_urlIsReturned() async throws {
        let expectedURL = URL(filePath: "/some/file/path")
        let expectedResult: Result<MediaFileProxy, MediaProviderError> = .success(.init(url: expectedURL))
        mediaLoader.mediaFileURL = expectedURL
        let result = await mediaProvider.loadFileFromSource(MediaSourceProxy(url: URL(staticString: "test/test1")), type: .png)
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_whenLoadFileFromSourceAndNoFileFromSourceExistsAndLoadContentSourceFails_failureIsReturned() async throws {
        let expectedResult: Result<MediaFileProxy, MediaProviderError> = .failure(.failedRetrievingFile)
        mediaLoader.mediaFileURL = nil
        let result = await mediaProvider.loadFileFromSource(MediaSourceProxy(url: URL(staticString: "test/test1")), type: .png)
        XCTAssertEqual(result, expectedResult)
    }
    
    private func loadTestImage() throws -> UIImage {
        let bundle = Bundle(for: classForCoder)
        guard let path = bundle.path(forResource: "test_image", ofType: "png"),
              let image = UIImage(contentsOfFile: path) else {
            throw MediaProviderTestsError.screenshotNotFound
        }
        return image
    }
}

enum MediaProviderTestsError: Error {
    case screenshotNotFound
}
