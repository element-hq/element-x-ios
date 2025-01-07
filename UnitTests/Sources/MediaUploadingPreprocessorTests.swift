//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import UniformTypeIdentifiers
import XCTest

@testable import ElementX

final class MediaUploadingPreprocessorTests: XCTestCase {
    var appSettings: AppSettings!
    var mediaUploadingPreprocessor: MediaUploadingPreprocessor!
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        appSettings.optimizeMediaUploads = false
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
        // Allow an increased execution time as we encode the video twice now.
        executionTimeAllowance = 180
        
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
        XCTAssertEqual(videoURL.pathExtension, "mp4", "The file extension should match the container we use.")
        
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
        XCTAssertEqual(videoInfo.thumbnailInfo?.size ?? 0, 33611, accuracy: 100)
        XCTAssertEqual(videoInfo.thumbnailInfo?.width, 800)
        XCTAssertEqual(videoInfo.thumbnailInfo?.height, 450)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .video(optimizedVideoURL, _, optimizedVideoInfo) = optimizedResult else {
            XCTFail("Failed processing asset")
            return
        }
        
        XCTAssertEqual(optimizedVideoURL.pathExtension, "mp4", "The file extension should match the container we use.")
        
        // Check optimised video info
        XCTAssertEqual(optimizedVideoInfo.mimetype, "video/mp4")
        XCTAssertEqual(optimizedVideoInfo.blurhash, "K22PJZx^DgadWAbbMuRio$")
        XCTAssertEqual(optimizedVideoInfo.size ?? 0, 1_431_959, accuracy: 100) // Note: This is slightly stupid because it is larger now 🤦‍♂️
        XCTAssertEqual(optimizedVideoInfo.width, 1280)
        XCTAssertEqual(optimizedVideoInfo.height, 720)
        XCTAssertEqual(optimizedVideoInfo.duration ?? 0, 30, accuracy: 100)
    }

    func testPortraitMp4VideoProcessing() async {
        // Allow an increased execution time as we encode the video twice now.
        executionTimeAllowance = 180
        
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
        XCTAssertEqual(videoURL.pathExtension, "mp4", "The file extension should match the container we use.")
        
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
        XCTAssertEqual(videoInfo.thumbnailInfo?.size ?? 0, 81515, accuracy: 100)
        XCTAssertEqual(videoInfo.thumbnailInfo?.width, 337)
        XCTAssertEqual(videoInfo.thumbnailInfo?.height, 600)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .video(optimizedVideoURL, _, optimizedVideoInfo) = optimizedResult else {
            XCTFail("Failed processing asset")
            return
        }
        
        XCTAssertEqual(optimizedVideoURL.pathExtension, "mp4", "The file extension should match the container we use.")
        
        // Check optimised video info
        XCTAssertEqual(optimizedVideoInfo.mimetype, "video/mp4")
        XCTAssertEqual(optimizedVideoInfo.blurhash, "K7BDNJD*0L%#sl_2~C9ZE1")
        XCTAssertEqual(optimizedVideoInfo.size ?? 0, 21_936_767, accuracy: 100)
        XCTAssertEqual(optimizedVideoInfo.width, 720)
        XCTAssertEqual(optimizedVideoInfo.height, 1280)
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
        XCTAssertEqual(imageInfo.thumbnailInfo?.size ?? 0, 87733, accuracy: 100)
        XCTAssertEqual(imageInfo.thumbnailInfo?.width, 800)
        XCTAssertEqual(imageInfo.thumbnailInfo?.height, 344)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(optimizedImageURL, thumbnailURL, optimizedImageInfo) = optimizedResult else {
            XCTFail("Failed processing asset")
            return
        }
        
        compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check optimised image info
        XCTAssertEqual(optimizedImageInfo.mimetype, "image/jpeg")
        XCTAssertEqual(optimizedImageInfo.blurhash, "K%I#.NofkC_4ayaxxujsWB")
        XCTAssertEqual(optimizedImageInfo.size ?? 0, 524_226, accuracy: 100)
        XCTAssertEqual(optimizedImageInfo.width, 2048)
        XCTAssertEqual(optimizedImageInfo.height, 879)
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
        XCTAssertEqual(imageInfo.blurhash, "KdE|0Ls+RP^-n*RP%OWAV@")
        XCTAssertEqual(imageInfo.size ?? 0, 4_414_666, accuracy: 100)
        XCTAssertEqual(imageInfo.width, 3024)
        XCTAssertEqual(imageInfo.height, 4032)
        
        XCTAssertNotNil(imageInfo.thumbnailInfo)
        XCTAssertEqual(imageInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(imageInfo.thumbnailInfo?.size ?? 0, 258_914, accuracy: 100)
        XCTAssertEqual(imageInfo.thumbnailInfo?.width, 600)
        XCTAssertEqual(imageInfo.thumbnailInfo?.height, 800)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(optimizedImageURL, thumbnailURL, optimizedImageInfo) = optimizedResult else {
            XCTFail("Failed processing asset")
            return
        }
        
        compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check optimised image info
        XCTAssertEqual(optimizedImageInfo.mimetype, "image/jpeg")
        XCTAssertEqual(optimizedImageInfo.blurhash, "KdE|0Ls+RP^-n*RP%OWAV@")
        XCTAssertEqual(optimizedImageInfo.size ?? 0, 1_462_937, accuracy: 100)
        XCTAssertEqual(optimizedImageInfo.width, 1536)
        XCTAssertEqual(optimizedImageInfo.height, 2048)
    }
    
    func testPNGImageProcessing() async {
        guard let url = Bundle(for: Self.self).url(forResource: "test_image.png", withExtension: nil) else {
            XCTFail("Failed retrieving test asset")
            return
        }
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(convertedImageURL, _, imageInfo) = result else {
            XCTFail("Failed processing asset")
            return
        }
        
        // Make sure the output file matches the image info.
        XCTAssertEqual(mimeType(from: convertedImageURL), "image/png", "PNGs should always be sent as PNG to preserve the alpha channel.")
        XCTAssertEqual(convertedImageURL.pathExtension, "png", "The file extension should match the MIME type.")
        
        // Check resulting image info
        XCTAssertEqual(imageInfo.mimetype, "image/png")
        XCTAssertEqual(imageInfo.blurhash, "K0TSUA~qfQ~qj[fQfQfQfQ")
        XCTAssertEqual(imageInfo.size ?? 0, 4868, accuracy: 100)
        XCTAssertEqual(imageInfo.width, 240)
        XCTAssertEqual(imageInfo.height, 240)
        
        XCTAssertNotNil(imageInfo.thumbnailInfo)
        XCTAssertEqual(imageInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(imageInfo.thumbnailInfo?.size ?? 0, 1725, accuracy: 100)
        XCTAssertEqual(imageInfo.thumbnailInfo?.width, 240)
        XCTAssertEqual(imageInfo.thumbnailInfo?.height, 240)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(optimizedImageURL, _, optimizedImageInfo) = optimizedResult else {
            XCTFail("Failed processing asset")
            return
        }
        
        // Make sure the output file matches the image info.
        XCTAssertEqual(mimeType(from: optimizedImageURL), "image/png", "PNGs should always be sent as PNG to preserve the alpha channel.")
        XCTAssertEqual(optimizedImageURL.pathExtension, "png", "The file extension should match the MIME type.")
        
        // Check optimised image info
        XCTAssertEqual(optimizedImageInfo.mimetype, "image/png")
        XCTAssertEqual(optimizedImageInfo.blurhash, "K0TSUA~qfQ~qj[fQfQfQfQ")
        XCTAssertEqual(optimizedImageInfo.size ?? 0, 8199, accuracy: 100)
        // Assert that resizing didn't upscale to the maxPixelSize.
        XCTAssertEqual(optimizedImageInfo.width, 240)
        XCTAssertEqual(optimizedImageInfo.height, 240)
    }
    
    func testHEICImageProcessing() async {
        guard let url = Bundle(for: Self.self).url(forResource: "test_apple_image.heic", withExtension: nil) else {
            XCTFail("Failed retrieving test asset")
            return
        }
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(convertedImageURL, thumbnailURL, imageInfo) = result else {
            XCTFail("Failed processing asset")
            return
        }
        
        compare(originalImageAt: url, toConvertedImageAt: convertedImageURL, withThumbnailAt: thumbnailURL)
        
        // Make sure the output file matches the image info.
        XCTAssertEqual(mimeType(from: convertedImageURL), "image/heic", "Unoptimised HEICs should always be sent as is.")
        XCTAssertEqual(convertedImageURL.pathExtension, "heic", "The file extension should match the MIME type.")
        
        // Check resulting image info
        XCTAssertEqual(imageInfo.mimetype, "image/heic")
        XCTAssertEqual(imageInfo.blurhash, "KGD]3ns:T00$kWxFXmt6xv")
        XCTAssertEqual(imageInfo.size ?? 0, 1_850_479, accuracy: 100)
        XCTAssertEqual(imageInfo.width, 3024)
        XCTAssertEqual(imageInfo.height, 4032)
        
        XCTAssertNotNil(imageInfo.thumbnailInfo)
        XCTAssertEqual(imageInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(imageInfo.thumbnailInfo?.size ?? 0, 218_108, accuracy: 100)
        XCTAssertEqual(imageInfo.thumbnailInfo?.width, 600)
        XCTAssertEqual(imageInfo.thumbnailInfo?.height, 800)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(optimizedImageURL, thumbnailURL, optimizedImageInfo) = optimizedResult else {
            XCTFail("Failed processing asset")
            return
        }
        
        compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
        
        // Make sure the output file matches the image info.
        XCTAssertEqual(mimeType(from: optimizedImageURL), "image/jpeg", "Optimised HEICs should always be converted to JPEG for compatibility.")
        XCTAssertEqual(optimizedImageURL.pathExtension, "jpeg", "The file extension should match the MIME type.")
        
        // Check optimised image info
        XCTAssertEqual(optimizedImageInfo.mimetype, "image/jpeg")
        XCTAssertEqual(optimizedImageInfo.blurhash, "KGD]3ns:T00#kWxFb^s:xv")
        XCTAssertEqual(optimizedImageInfo.size ?? 0, 1_049_393, accuracy: 100)
        XCTAssertEqual(optimizedImageInfo.width, 1536)
        XCTAssertEqual(optimizedImageInfo.height, 2048)
    }
    
    func testGIFImageProcessing() async {
        guard let url = Bundle(for: Self.self).url(forResource: "test_animated_image.gif", withExtension: nil) else {
            XCTFail("Failed retrieving test asset")
            return
        }
        guard let originalSize = try? FileManager.default.sizeForItem(at: url), originalSize > 0 else {
            XCTFail("Failed fetching test asset's original size")
            return
        }
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(convertedImageURL, _, imageInfo) = result else {
            XCTFail("Failed processing asset")
            return
        }
        
        // Make sure the output file matches the image info.
        XCTAssertEqual(mimeType(from: convertedImageURL), "image/gif", "GIFs should always be sent as GIF to preserve the animation.")
        XCTAssertEqual(convertedImageURL.pathExtension, "gif", "The file extension should match the MIME type.")
        
        // Check resulting image info
        XCTAssertEqual(imageInfo.mimetype, "image/gif")
        XCTAssertEqual(imageInfo.blurhash, "K7SY{qs;%NxuRjof~qozIU")
        XCTAssertEqual(imageInfo.size ?? 0, UInt64(originalSize), accuracy: 100)
        XCTAssertEqual(imageInfo.width, 490)
        XCTAssertEqual(imageInfo.height, 498)
        
        XCTAssertNotNil(imageInfo.thumbnailInfo)
        XCTAssertEqual(imageInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(imageInfo.thumbnailInfo?.size ?? 0, 29511, accuracy: 100)
        XCTAssertEqual(imageInfo.thumbnailInfo?.width, 490)
        XCTAssertEqual(imageInfo.thumbnailInfo?.height, 498)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(optimizedImageURL, _, optimizedImageInfo) = optimizedResult else {
            XCTFail("Failed processing asset")
            return
        }
        
        // Make sure the output file matches the image info.
        XCTAssertEqual(mimeType(from: optimizedImageURL), "image/gif", "GIFs should always be sent as GIF to preserve the animation.")
        XCTAssertEqual(optimizedImageURL.pathExtension, "gif", "The file extension should match the MIME type.")
        
        // Ensure optimised image is still the same as the original image.
        XCTAssertEqual(optimizedImageInfo.mimetype, "image/gif")
        XCTAssertEqual(optimizedImageInfo.blurhash, "K7SY{qs;%NxuRjof~qozIU")
        XCTAssertEqual(optimizedImageInfo.size ?? 0, UInt64(originalSize), accuracy: 100)
        XCTAssertEqual(optimizedImageInfo.width, 490)
        XCTAssertEqual(optimizedImageInfo.height, 498)
    }
    
    func testRotatedImageProcessing() async {
        guard let url = Bundle(for: Self.self).url(forResource: "test_rotated_image.jpg", withExtension: nil) else {
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
        XCTAssertEqual(imageInfo.width, 2848)
        XCTAssertEqual(imageInfo.height, 4272)
        
        XCTAssertNotNil(imageInfo.thumbnailInfo)
        XCTAssertEqual(imageInfo.thumbnailInfo?.width, 533)
        XCTAssertEqual(imageInfo.thumbnailInfo?.height, 800)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .image(optimizedImageURL, thumbnailURL, optimizedImageInfo) = optimizedResult else {
            XCTFail("Failed processing asset")
            return
        }
        
        compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check optimised image info
        XCTAssertEqual(optimizedImageInfo.mimetype, "image/jpeg")
        XCTAssertEqual(optimizedImageInfo.width, 1365)
        XCTAssertEqual(optimizedImageInfo.height, 2048)
    }
    
    // MARK: - Private
    
    private func compare(originalImageAt originalImageURL: URL, toConvertedImageAt convertedImageURL: URL, withThumbnailAt thumbnailURL: URL) {
        guard let originalImageData = try? Data(contentsOf: originalImageURL),
              let originalImage = UIImage(data: originalImageData),
              let convertedImageData = try? Data(contentsOf: convertedImageURL),
              let convertedImage = UIImage(data: convertedImageData) else {
            fatalError()
        }
        
        if appSettings.optimizeMediaUploads {
            // Check that new image has been scaled within the requirements for an optimised image
            XCTAssert(convertedImage.size.width <= MediaUploadingPreprocessor.Constants.optimizedMaxPixelSize)
            XCTAssert(convertedImage.size.height <= MediaUploadingPreprocessor.Constants.optimizedMaxPixelSize)
        } else {
            // Check that the file name is preserved
            XCTAssertEqual(originalImageURL.lastPathComponent, convertedImageURL.lastPathComponent)
            // Check that new image is the same size as the original one
            XCTAssertEqual(originalImage.size, convertedImage.size)
        }
        
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
    
    private func mimeType(from url: URL) -> String? {
        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
              let typeIdentifier = CGImageSourceGetType(imageSource),
              let type = UTType(typeIdentifier as String),
              let mimeType = type.preferredMIMEType else {
            XCTFail("Failed to get mimetype from URL.")
            return nil
        }
        return mimeType
    }
}
