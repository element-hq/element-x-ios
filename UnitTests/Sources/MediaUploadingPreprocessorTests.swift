//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

final class MediaUploadingPreprocessorTests: XCTestCase {
    var appSettings: AppSettings!
    var mediaUploadingPreprocessor: MediaUploadingPreprocessor!
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        ServiceLocator.shared.register(appSettings: appSettings)
        mediaUploadingPreprocessor = MediaUploadingPreprocessor(appSettings: appSettings)
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }
    
    func testAudioFileProcessing() async {
        guard let url = Bundle(for: Self.self).url(forResource: "test_audio.mp3", withExtension: nil) else {
            XCTFail("Failed retrieving test asset")
            return
        }
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .audio(audioURL, audioInfo) = result else {
            XCTFail("Failed processing asset")
            return
        }
        
        // Check that the file name is preserved
        XCTAssertEqual(audioURL.lastPathComponent, "test_audio.mp3")
        
        XCTAssertEqual(audioInfo.mimetype, "audio/mpeg")
        XCTAssertEqual(audioInfo.duration ?? 0, 27, accuracy: 100)
        XCTAssertEqual(audioInfo.size ?? 0, 764_176, accuracy: 100)
    }
    
    func testLandscapeMovVideoProcessing() async {
        guard let url = Bundle(for: Self.self).url(forResource: "landscape_test_video.mov", withExtension: nil) else {
            XCTFail("Failed retrieving test asset")
            return
        }
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .video(videoURL, thumbnailURL, videoInfo) = result else {
            XCTFail("Failed processing asset")
            return
        }
        
        // Check that the file name is preserved
        XCTAssertEqual(videoURL.lastPathComponent, "landscape_test_video.mp4")
        
        // Check that the thumbnail is generated correctly
        guard let thumbnailData = try? Data(contentsOf: thumbnailURL),
              let thumbnail = UIImage(data: thumbnailData) else {
            XCTFail("Invalid thumbnail")
            return
        }
        
        XCTAssert(thumbnail.size.width <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.width)
        XCTAssert(thumbnail.size.height <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.height)
        
        // Check resulting video info
        XCTAssertEqual(videoInfo.mimetype, "video/mp4")
        XCTAssertEqual(videoInfo.blurhash, "K22PJZx^DgadWAbbMuRio$")
        XCTAssertEqual(videoInfo.size ?? 0, 1_431_959, accuracy: 100)
        XCTAssertEqual(videoInfo.width, 1280)
        XCTAssertEqual(videoInfo.height, 720)
        XCTAssertEqual(videoInfo.duration ?? 0, 30, accuracy: 100)
        
        XCTAssertNotNil(videoInfo.thumbnailInfo)
        XCTAssertEqual(videoInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(videoInfo.thumbnailInfo?.size ?? 0, 34206, accuracy: 100)
        XCTAssertEqual(videoInfo.thumbnailInfo?.width, 800)
        XCTAssertEqual(videoInfo.thumbnailInfo?.height, 450)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .video(_, _, optimizedVideoInfo) = optimizedResult else {
            XCTFail("Failed processing asset")
            return
        }
        
        // Check optimised video info
        XCTAssertEqual(optimizedVideoInfo.mimetype, "video/mp4")
        XCTAssertEqual(optimizedVideoInfo.blurhash, "K32PJbx^I7jYaebHMvV?o$")
        XCTAssertEqual(optimizedVideoInfo.size ?? 0, 4_090_898, accuracy: 100) // Note: This is slightly stupid because it is larger now 🤦‍♂️
        XCTAssertEqual(optimizedVideoInfo.width, 640)
        XCTAssertEqual(optimizedVideoInfo.height, 360)
        XCTAssertEqual(optimizedVideoInfo.duration ?? 0, 30, accuracy: 100)
    }

    func testPortraitMp4VideoProcessing() async {
        guard let url = Bundle(for: Self.self).url(forResource: "portrait_test_video.mp4", withExtension: nil) else {
            XCTFail("Failed retrieving test asset")
            return
        }
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .video(videoURL, thumbnailURL, videoInfo) = result else {
            XCTFail("Failed processing asset")
            return
        }
        
        // Check that the file name is preserved
        XCTAssertEqual(videoURL.lastPathComponent, "portrait_test_video.mp4")
        
        // Check that the thumbnail is generated correctly
        guard let thumbnailData = try? Data(contentsOf: thumbnailURL),
              let thumbnail = UIImage(data: thumbnailData) else {
            XCTFail("Invalid thumbnail")
            return
        }
        
        XCTAssert(thumbnail.size.width <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.width)
        XCTAssert(thumbnail.size.height <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.height)
        
        // Check resulting video info
        XCTAssertEqual(videoInfo.mimetype, "video/mp4")
        XCTAssertEqual(videoInfo.blurhash, "K7C$_zs;0LKQMx^+~B9GIU")
        XCTAssertEqual(videoInfo.size ?? 0, 9_775_822, accuracy: 100)
        XCTAssertEqual(videoInfo.width, 1080)
        XCTAssertEqual(videoInfo.height, 1920)
        XCTAssertEqual(videoInfo.duration ?? 0, 21, accuracy: 100)
        
        XCTAssertNotNil(videoInfo.thumbnailInfo)
        XCTAssertEqual(videoInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(videoInfo.thumbnailInfo?.size ?? 0, 83220, accuracy: 100)
        XCTAssertEqual(videoInfo.thumbnailInfo?.width, 337)
        XCTAssertEqual(videoInfo.thumbnailInfo?.height, 600)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .video(_, _, optimizedVideoInfo) = optimizedResult else {
            XCTFail("Failed processing asset")
            return
        }
        
        // Check optimised video info
        XCTAssertEqual(optimizedVideoInfo.mimetype, "video/mp4")
        XCTAssertEqual(optimizedVideoInfo.blurhash, "K7BDNJD*0L%#sl_2~C9ZE1")
        XCTAssertEqual(optimizedVideoInfo.size ?? 0, 6_520_897, accuracy: 100)
        XCTAssertEqual(optimizedVideoInfo.width, 360)
        XCTAssertEqual(optimizedVideoInfo.height, 640)
        XCTAssertEqual(optimizedVideoInfo.duration ?? 0, 30, accuracy: 100)
    }
    
    func testLandscapeImageProcessing() async {
        guard let url = Bundle(for: Self.self).url(forResource: "landscape_test_image.jpg", withExtension: nil) else {
            XCTFail("Failed retrieving test asset")
            return
        }
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(convertedImageURL, thumbnailURL, imageInfo) = result else {
            XCTFail("Failed processing asset")
            return
        }
        
        compare(originalImageAt: url, toConvertedImageAt: convertedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check resulting image info
        XCTAssertEqual(imageInfo.mimetype, "image/jpeg")
        XCTAssertEqual(imageInfo.blurhash, "K%I#.NofkC_4ayayxujsWB")
        XCTAssertEqual(imageInfo.size ?? 0, 3_305_795, accuracy: 100)
        XCTAssertEqual(imageInfo.width, 6103)
        XCTAssertEqual(imageInfo.height, 2621)
        
        XCTAssertNotNil(imageInfo.thumbnailInfo)
        XCTAssertEqual(imageInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(imageInfo.thumbnailInfo?.size ?? 0, 89553, accuracy: 100)
        XCTAssertEqual(imageInfo.thumbnailInfo?.width, 800)
        XCTAssertEqual(imageInfo.thumbnailInfo?.height, 344)
    }
    
    func testPortraitImageProcessing() async {
        guard let url = Bundle(for: Self.self).url(forResource: "portrait_test_image.jpg", withExtension: nil) else {
            XCTFail("Failed retrieving test asset")
            return
        }
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(convertedImageURL, thumbnailURL, imageInfo) = result else {
            XCTFail("Failed processing asset")
            return
        }
        
        compare(originalImageAt: url, toConvertedImageAt: convertedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check resulting image info
        XCTAssertEqual(imageInfo.mimetype, "image/jpeg")
        XCTAssertEqual(imageInfo.blurhash, "KdE:ets+RP^-n*RP%OWAV@")
        XCTAssertEqual(imageInfo.size ?? 0, 4_414_666, accuracy: 100)
        XCTAssertEqual(imageInfo.width, 3024)
        XCTAssertEqual(imageInfo.height, 4032)
        
        XCTAssertNotNil(imageInfo.thumbnailInfo)
        XCTAssertEqual(imageInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(imageInfo.thumbnailInfo?.size ?? 0, 264_500, accuracy: 100)
        XCTAssertEqual(imageInfo.thumbnailInfo?.width, 600)
        XCTAssertEqual(imageInfo.thumbnailInfo?.height, 800)
    }
    
    // MARK: - Private
    
    private func compare(originalImageAt originalImageURL: URL, toConvertedImageAt convertedImageURL: URL, withThumbnailAt thumbnailURL: URL) {
        guard let originalImageData = try? Data(contentsOf: originalImageURL),
              let originalImage = UIImage(data: originalImageData),
              let convertedImageData = try? Data(contentsOf: convertedImageURL),
              let convertedImage = UIImage(data: convertedImageData) else {
            fatalError()
        }
        
        // Check that the file name is preserved
        XCTAssertEqual(originalImageURL.lastPathComponent, convertedImageURL.lastPathComponent)
        
        // Check that new image is the same size as the original one
        XCTAssertEqual(originalImage.size, convertedImage.size)
        
        // Check that the GPS data has been stripped
        let originalMetadata = metadata(from: originalImageData)
        XCTAssertNotNil(originalMetadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)"))
        
        let convertedMetadata = metadata(from: convertedImageData)
        XCTAssertNil(convertedMetadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)"))
        
        // Check that the thumbnail is generated correctly
        guard let thumbnailData = try? Data(contentsOf: thumbnailURL),
              let thumbnail = UIImage(data: thumbnailData) else {
            XCTFail("Invalid thumbnail")
            return
        }
        
        if thumbnail.size.width > thumbnail.size.height {
            XCTAssert(thumbnail.size.width <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.width)
            XCTAssert(thumbnail.size.height <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.height)
        } else {
            XCTAssert(thumbnail.size.width <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.height)
            XCTAssert(thumbnail.size.height <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.width)
        }
        
        let thumbnailMetadata = metadata(from: thumbnailData)
        XCTAssertNil(thumbnailMetadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)"))
    }
    
    private func metadata(from imageData: Data) -> NSDictionary {
        guard let imageSource = CGImageSourceCreateWithData(imageData as NSData, nil) else {
            XCTFail("Invalid asset")
            return [:]
        }
        
        guard let convertedMetadata: NSDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) else {
            XCTFail("Test asset is expected to contain metadata")
            return [:]
        }
        
        return convertedMetadata
    }
}
