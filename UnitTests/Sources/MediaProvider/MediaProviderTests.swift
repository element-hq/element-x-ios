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
    private let mediaProxy = MockMediaProxy()
    private let fileCache = MockFileCache()
    private var imageCache: MockImageCache!
    private var backgroundTaskService = MockBackgroundTaskService()
    
    var mediaProvider: MediaProvider!
    
    override func setUp() {
        imageCache = MockImageCache(name: "Test")
        mediaProvider = MediaProvider(mediaProxy: mediaProxy,
                                      imageCache: imageCache,
                                      fileCache: fileCache,
                                      backgroundTaskService: backgroundTaskService)
    }

    func test_whenImageFromSourceWithSourceNil_nilReturned() throws {
        let image = mediaProvider.imageFromSource(nil, avatarSize: .room(on: .timeline))
        XCTAssertNil(image)
    }
    
    func test_whenImageFromSourceWithSourceNotNilAndImageCacheContainsImage_ImageIsReturned() throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let urlString = "test"
        let key = "\(urlString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImagesInMemory[key] = imageForKey
        let image = mediaProvider.imageFromSource(MediaSourceProxy(urlString: urlString), avatarSize: avatarSize)
        XCTAssertEqual(image, imageForKey)
    }
    
    func test_whenImageFromSourceWithSourceNotNilAndImageNotCached_nilReturned() throws {
        let image = mediaProvider.imageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: .room(on: .timeline))
        XCTAssertNil(image)
    }
    
    func test_whenImageFromURLStringWithURLStringNil_nilReturned() throws {
        let image = mediaProvider.imageFromURLString(nil, avatarSize: .room(on: .timeline))
        XCTAssertNil(image)
    }

    func test_whenImageFromURLStringWithURLStringNotNilAndImageCacheContainsImage_imageIsReturned() throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let urlString = "test"
        let key = "\(urlString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImagesInMemory[key] = imageForKey
        let image = mediaProvider.imageFromURLString("test", avatarSize: avatarSize)
        XCTAssertEqual(image, imageForKey)
    }
    
    func test_whenImageFromURLStringWithURLStringNotNilAndImageNotCached_nilReturned() throws {
        let image = mediaProvider.imageFromURLString("test", avatarSize: .room(on: .timeline))
        XCTAssertNil(image)
    }
    
    func test_whenLoadImageFromSourceAndImageCacheContainsImage_successIsReturned() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let urlString = "test"
        let key = "\(urlString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImagesInMemory[key] = imageForKey
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(urlString: urlString), avatarSize: avatarSize)
        XCTAssertEqual(Result.success(imageForKey), result)
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageSucceeds_successIsReturned() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let urlString = "test"
        let key = "\(urlString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCache.retrievedImages[key] = imageForKey
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(urlString: urlString), avatarSize: avatarSize)
        XCTAssertEqual(Result.success(imageForKey), result)
    }

    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFails_imageThumbnailIsLoaded() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let expectedImage = try loadTestImage()
        mediaProxy.mediaThumbnailData = expectedImage.pngData()
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: avatarSize)
        switch result {
        case .success(let image):
            XCTAssertEqual(image.pngData(), expectedImage.pngData())
        case .failure:
            XCTFail("Should be success")
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFails_imageIsStored() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let urlString = "test"
        let key = "\(urlString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let expectedImage = try loadTestImage()
        mediaProxy.mediaThumbnailData = expectedImage.pngData()
        _ = await mediaProvider.loadImageFromSource(MediaSourceProxy(urlString: urlString), avatarSize: avatarSize)
        let storedImage = try XCTUnwrap(imageCache.storedImages[key])
        XCTAssertEqual(expectedImage.pngData(), storedImage.pngData())
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndNoAvatarSize_imageContentIsLoaded() async throws {
        let expectedImage = try loadTestImage()
        mediaProxy.mediaContentData = expectedImage.pngData()
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: nil)
        switch result {
        case .success(let image):
            XCTAssertEqual(image.pngData(), expectedImage.pngData())
        case .failure:
            XCTFail("Should be success")
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndLoadImageThumbnailFails_errorIsThrown() async throws {
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: AvatarSize.room(on: .timeline))
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.failedRetrievingImage)
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndNoAvatarSizeAndLoadImageContentFails_errorIsThrown() async throws {
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: nil)
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.failedRetrievingImage)
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndImageThumbnailIsLoadedWithCorruptedData_errorIsThrown() async throws {
        mediaProxy.mediaThumbnailData = Data()
        let result = await mediaProvider.loadImageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: AvatarSize.room(on: .timeline))
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.invalidImageData)
        }
    }
    
    func test_whenFileFromSourceWithSourceNil_nilIsReturned() throws {
        let url = mediaProvider.fileFromSource(nil, fileExtension: "png")
        XCTAssertNil(url)
    }
    
    func test_whenFileFromSourceWithSource_correctValuesAreReturned() throws {
        let expectedURL = URL(filePath: "/some/file/path")
        fileCache.fileURLToReturn = expectedURL
        let url = mediaProvider.fileFromSource(MediaSourceProxy(urlString: "test/test1"), fileExtension: "png")
        XCTAssertEqual(fileCache.fileKey, "test1")
        XCTAssertEqual(fileCache.fileExtension, "png")
        XCTAssertEqual(url?.absoluteString, expectedURL.absoluteString)
    }
    
    func test_whenLoadFileFromSourceAndFileFromSourceExists_urlIsReturned() async throws {
        let expectedURL = URL(filePath: "/some/file/path")
        let expectedResult: Result<URL, MediaProviderError> = .success(expectedURL)
        fileCache.fileURLToReturn = expectedURL
        let result = await mediaProvider.loadFileFromSource(MediaSourceProxy(urlString: "test/test1"), fileExtension: "png")
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_whenLoadFileFromSourceAndNoFileFromSourceExists_mediaLoadedFromSource() async throws {
        let expectedURL = URL(filePath: "/some/file/path")
        let expectedResult: Result<URL, MediaProviderError> = .success(expectedURL)
        mediaProxy.mediaContentData = try loadTestImage().pngData()
        fileCache.storeURLToReturn = expectedURL
        let result = await mediaProvider.loadFileFromSource(MediaSourceProxy(urlString: "test/test1"), fileExtension: "png")
        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(mediaProxy.mediaContentData, fileCache.storedData)
        XCTAssertEqual("test1", fileCache.storedFileKey)
        XCTAssertEqual("png", fileCache.storedFileExtension)
    }
    
    func test_whenLoadFileFromSourceAndNoFileFromSourceExistsAndLoadContentSourceFails_failureIsReturned() async throws {
        let expectedResult: Result<URL, MediaProviderError> = .failure(.failedRetrievingImage)
        mediaProxy.mediaContentData = nil
        let result = await mediaProvider.loadFileFromSource(MediaSourceProxy(urlString: "test/test1"), fileExtension: "png")
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_whenLoadFileFromSourceAndNoFileFromSourceExistsAndStoreDataFails_failureIsReturned() async throws {
        let expectedResult: Result<URL, MediaProviderError> = .failure(.failedRetrievingImage)
        mediaProxy.mediaContentData = try loadTestImage().pngData()
        let result = await mediaProvider.loadFileFromSource(MediaSourceProxy(urlString: "test/test1"), fileExtension: "png")
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_whenFileFromURLStringAndURLIsNil_nilIsReturned() async throws {
        mediaProxy.mediaContentData = try loadTestImage().pngData()
        let url = mediaProvider.fileFromURLString(nil, fileExtension: "png")
        XCTAssertNil(url)
    }
    
    func test_whenFileFromURLString_correctURLIsReturned() throws {
        let expectedURL = URL(filePath: "/some/file/path")
        fileCache.fileURLToReturn = expectedURL
        let url = mediaProvider.fileFromURLString("test/test1", fileExtension: "png")
        XCTAssertEqual(url?.absoluteString, expectedURL.absoluteString)
    }
    
    func test_whenLoadFileFromURLString_correctURLIsReturned() async throws {
        let expectedURL = URL(filePath: "/some/file/path")
        let expectedResult: Result<URL, MediaProviderError> = .success(expectedURL)
        fileCache.fileURLToReturn = expectedURL
        let result = await mediaProvider.loadFileFromURLString("test/test1", fileExtension: "png")
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
