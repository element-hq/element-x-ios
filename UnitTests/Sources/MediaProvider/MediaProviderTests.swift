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

final class MediaProviderTests: XCTestCase {
    private let mediaProxyMock = MediaProxyMock()
    private let fileCacheMock = FileCacheMock()
    private var imageCacheMock: ImageCacheMock!
    @MainActor private var backgroundTaskServiceMock = BackgroundTaskServiceMock()
    var sut: MediaProvider!
    
    @MainActor override func setUp() {
        imageCacheMock = ImageCacheMock(name: "Test")
        sut = MediaProvider(mediaProxy: mediaProxyMock,
                            imageCache: imageCacheMock,
                            fileCache: fileCacheMock,
                            backgroundTaskService: backgroundTaskServiceMock)
    }

    func test_whenImageFromSourceWithSourceNil_nilReturned() throws {
        let image = sut.imageFromSource(nil, avatarSize: .room(on: .timeline))
        XCTAssertNil(image)
    }
    
    func test_whenImageFromSourceWithSourceNotNilAndImageCacheContainsImage_ImageIsReturned() throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let urlString = "test"
        let key = "\(urlString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCacheMock.retrievedImagesInMemory[key] = imageForKey
        let image = sut.imageFromSource(MediaSourceProxy(urlString: urlString), avatarSize: avatarSize)
        XCTAssertEqual(image, imageForKey)
    }
    
    func test_whenImageFromSourceWithSourceNotNilAndImageNotCached_nilReturned() throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let image = sut.imageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: avatarSize)
        XCTAssertNil(image)
    }
    
    func test_whenImageFromURLStringWithUrlStringNil_nilReturned() throws {
        let image = sut.imageFromURLString(nil, avatarSize: .room(on: .timeline))
        XCTAssertNil(image)
    }

    func test_whenImageFromURLStringWithUrlStringNotNilAndImageCacheContainsImage_imageIsReturned() throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let urlString = "test"
        let key = "\(urlString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCacheMock.retrievedImagesInMemory[key] = imageForKey
        let image = sut.imageFromURLString("test", avatarSize: avatarSize)
        XCTAssertEqual(image, imageForKey)
    }
    
    func test_whenImageFromURLStringWithUrlStringNotNilAndImageNotCached_nilReturned() throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let image = sut.imageFromURLString("test", avatarSize: avatarSize)
        XCTAssertNil(image)
    }
    
    func test_whenLoadImageFromSourceAndImageCacheContainsImage_successIsReturned() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let urlString = "test"
        let key = "\(urlString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCacheMock.retrievedImagesInMemory[key] = imageForKey
        let result = await sut.loadImageFromSource(MediaSourceProxy(urlString: urlString), avatarSize: avatarSize)
        XCTAssertEqual(Result.success(imageForKey), result)
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageSucceeds_successIsReturned() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let urlString = "test"
        let key = "\(urlString){\(avatarSize.scaledValue),\(avatarSize.scaledValue)}"
        let imageForKey = UIImage()
        imageCacheMock.retrievedImages[key] = imageForKey
        let result = await sut.loadImageFromSource(MediaSourceProxy(urlString: urlString), avatarSize: avatarSize)
        XCTAssertEqual(Result.success(imageForKey), result)
    }

    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFails_imageThumbnailIsLoaded() async throws {
        let avatarSize = AvatarSize.room(on: .timeline)
        let expectedImage = try sampleScreenshot()
        mediaProxyMock.loadMediaThumbnailForSourceData = expectedImage.pngData()
        let result = await sut.loadImageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: avatarSize)
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
        let expectedImage = try sampleScreenshot()
        mediaProxyMock.loadMediaThumbnailForSourceData = expectedImage.pngData()
        _ = await sut.loadImageFromSource(MediaSourceProxy(urlString: urlString), avatarSize: avatarSize)
        let storedImage = try XCTUnwrap(imageCacheMock.storedImages[key])
        XCTAssertEqual(expectedImage.pngData(), storedImage.pngData())
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndNoAvatarSize_imageContentIsLoaded() async throws {
        let expectedImage = try sampleScreenshot()
        mediaProxyMock.loadMediaContentForSourceData = expectedImage.pngData()
        let result = await sut.loadImageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: nil)
        switch result {
        case .success(let image):
            XCTAssertEqual(image.pngData(), expectedImage.pngData())
        case .failure:
            XCTFail("Should be success")
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndLoadImageThumbnailFails_errorIsThrown() async throws {
        let result = await sut.loadImageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: AvatarSize.room(on: .timeline))
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.failedRetrievingImage)
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndNoAvatarSizeAndLoadImageContentFails_errorIsThrown() async throws {
        let result = await sut.loadImageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: nil)
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.failedRetrievingImage)
        }
    }
    
    func test_whenLoadImageFromSourceAndImageNotCachedAndRetrieveImageFailsAndImageThumbnailIsLoadedWithCorruptedData_errorIsThrown() async throws {
        mediaProxyMock.loadMediaThumbnailForSourceData = Data()
        let result = await sut.loadImageFromSource(MediaSourceProxy(urlString: "test"), avatarSize: AvatarSize.room(on: .timeline))
        switch result {
        case .success:
            XCTFail("Should fail")
        case .failure(let error):
            XCTAssertEqual(error, MediaProviderError.invalidImageData)
        }
    }
    
    func test_whenFileFromSourceWithSourceNil_nilIsReturned() throws {
        let url = sut.fileFromSource(nil, fileExtension: "png")
        XCTAssertNil(url)
    }
    
    func test_whenFileFromSourceWithSource_correctValuesAreReturned() throws {
        let expectedURL = try XCTUnwrap(URL(string: "some_url"))
        fileCacheMock.fileURLToReturn = expectedURL
        let url = sut.fileFromSource(MediaSourceProxy(urlString: "test/test1"), fileExtension: "png")
        XCTAssertEqual(fileCacheMock.fileKey, "test1")
        XCTAssertEqual(fileCacheMock.fileExtension, "png")
        XCTAssertEqual(url?.absoluteString, expectedURL.absoluteString)
    }
    
    func test_whenLoadFileFromSourceAndFileFromSourceExists_urlIsReturned() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "some_url"))
        let expectedResult: Result<URL, MediaProviderError> = .success(expectedURL)
        fileCacheMock.fileURLToReturn = expectedURL
        let result = await sut.loadFileFromSource(MediaSourceProxy(urlString: "test/test1"), fileExtension: "png")
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_whenLoadFileFromSourceAndNoFileFromSourceExists_mediaLoadedFromSource() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "some_url"))
        let expectedResult: Result<URL, MediaProviderError> = .success(expectedURL)
        mediaProxyMock.loadMediaContentForSourceData = try sampleScreenshot().pngData()
        fileCacheMock.storeURLToReturn = expectedURL
        let result = await sut.loadFileFromSource(MediaSourceProxy(urlString: "test/test1"), fileExtension: "png")
        XCTAssertEqual(result, expectedResult)
        XCTAssertEqual(mediaProxyMock.loadMediaContentForSourceData, fileCacheMock.storedData)
        XCTAssertEqual("test1", fileCacheMock.storedFileKey)
        XCTAssertEqual("png", fileCacheMock.storedFileExtension)
    }
    
    func test_whenLoadFileFromSourceAndNoFileFromSourceExistsAndLoadContentSourceFails_failureIsReturned() async throws {
        let expectedResult: Result<URL, MediaProviderError> = .failure(.failedRetrievingImage)
        mediaProxyMock.loadMediaContentForSourceData = nil
        let result = await sut.loadFileFromSource(MediaSourceProxy(urlString: "test/test1"), fileExtension: "png")
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_whenLoadFileFromSourceAndNoFileFromSourceExistsAndStoreDataFails_failureIsReturned() async throws {
        let expectedResult: Result<URL, MediaProviderError> = .failure(.failedRetrievingImage)
        mediaProxyMock.loadMediaContentForSourceData = try sampleScreenshot().pngData()
        let result = await sut.loadFileFromSource(MediaSourceProxy(urlString: "test/test1"), fileExtension: "png")
        XCTAssertEqual(result, expectedResult)
    }
    
    func test_whenFileFromURLStringAndURLIsNil_nilIsReturned() async throws {
        mediaProxyMock.loadMediaContentForSourceData = try sampleScreenshot().pngData()
        let url = sut.fileFromURLString(nil, fileExtension: "png")
        XCTAssertNil(url)
    }
    
    func test_whenFileFromURLString_correctURLIsReturned() throws {
        let expectedURL = try XCTUnwrap(URL(string: "some_url"))
        fileCacheMock.fileURLToReturn = expectedURL
        let url = sut.fileFromURLString("test/test1", fileExtension: "png")
        XCTAssertEqual(url?.absoluteString, expectedURL.absoluteString)
    }
    
    func test_whenLoadFileFromURLString_correctURLIsReturned() async throws {
        let expectedURL = try XCTUnwrap(URL(string: "some_url"))
        let expectedResult: Result<URL, MediaProviderError> = .success(expectedURL)
        fileCacheMock.fileURLToReturn = expectedURL
        let result = await sut.loadFileFromURLString("test/test1", fileExtension: "png")
        XCTAssertEqual(result, expectedResult)
    }
    
    private func sampleScreenshot() throws -> UIImage {
        let bundle = Bundle(for: classForCoder)
        guard let path = bundle.path(forResource: "sample_screenshot", ofType: "png"),
              let image = UIImage(contentsOfFile: path) else {
            throw ImageAnonymizerTestsError.screenshotNotFound
        }
        return image
    }
}
