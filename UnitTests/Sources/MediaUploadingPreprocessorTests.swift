//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import SwiftUI
import Testing
import UniformTypeIdentifiers

@Suite
final class MediaUploadingPreprocessorTests {
    let maxUploadSize: UInt = 100 * 1024 * 1024
    var appSettings: AppSettings!
    var mediaUploadingPreprocessor: MediaUploadingPreprocessor!
    
    init() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        appSettings.optimizeMediaUploads = false
        ServiceLocator.shared.register(appSettings: appSettings)
        mediaUploadingPreprocessor = MediaUploadingPreprocessor(appSettings: appSettings)
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    @Test
    func audioFileProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "test_audio.mp3", withExtension: nil), "Failed retrieving test asset")
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .audio(audioURL, audioInfo) = result else {
            Issue.record("Failed processing asset")
            return
        }
        
        // Check that the file name is preserved
        #expect(audioURL.lastPathComponent == "test_audio.mp3")
        
        #expect(audioInfo.mimetype == "audio/mpeg")
        #expect(abs(Double(audioInfo.duration ?? 0) - 27) <= 100)
        #expect(abs(Double(audioInfo.size ?? 0) - 194_811) <= 100)
    }
    
    @Test
    func landscapeMovVideoProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "landscape_test_video.mov", withExtension: nil), "Failed retrieving test asset")
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .video(videoURL, thumbnailURL, videoInfo) = result else {
            Issue.record("Failed processing asset")
            return
        }
        
        // Check that the file name is preserved
        #expect(videoURL.lastPathComponent == "landscape_test_video.mp4")
        #expect(videoURL.pathExtension == "mp4", "The file extension should match the container we use.")
        
        // Check that the thumbnail is generated correctly
        let thumbnailData = try Data(contentsOf: thumbnailURL)
        let thumbnail = try #require(UIImage(data: thumbnailData), "Invalid thumbnail")
        
        #expect(thumbnail.size.width <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.width)
        #expect(thumbnail.size.height <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.height)
        
        // Check resulting video info
        #expect(videoInfo.mimetype == "video/mp4")
        #expect(videoInfo.blurhash == "K9F$LJZ9,+8yA9-:yT,@%1")
        #expect(abs(Double(videoInfo.size ?? 0) - 4_016_620) <= 100)
        #expect(videoInfo.width == 1280)
        #expect(videoInfo.height == 720)
        #expect(abs(Double(videoInfo.duration ?? 0) - 30) <= 100)
        
        #expect(videoInfo.thumbnailInfo != nil)
        #expect(videoInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(abs(Double(videoInfo.thumbnailInfo?.size ?? 0) - 183_093) <= 100)
        #expect(videoInfo.thumbnailInfo?.width == 800)
        #expect(videoInfo.thumbnailInfo?.height == 450)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .video(optimizedVideoURL, _, optimizedVideoInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        #expect(optimizedVideoURL.pathExtension == "mp4", "The file extension should match the container we use.")
        
        // Check optimised video info
        #expect(optimizedVideoInfo.mimetype == "video/mp4")
        #expect(optimizedVideoInfo.blurhash == "K9F$LJZ9,+8yA9-:yT,@%1")
        #expect(abs(Double(optimizedVideoInfo.size ?? 0) - 4_016_620) <= 100) // Note: The video is already 720p so it doesn't change size.
        #expect(optimizedVideoInfo.width == 1280)
        #expect(optimizedVideoInfo.height == 720)
        #expect(abs(Double(optimizedVideoInfo.duration ?? 0) - 30) <= 100)
    }
    
    @Test
    func portraitMp4VideoProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "portrait_test_video.mp4", withExtension: nil), "Failed retrieving test asset")
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .video(videoURL, thumbnailURL, videoInfo) = result else {
            Issue.record("Failed processing asset")
            return
        }
        
        // Check that the file name is preserved
        #expect(videoURL.lastPathComponent == "portrait_test_video.mp4")
        #expect(videoURL.pathExtension == "mp4", "The file extension should match the container we use.")
        
        // Check that the thumbnail is generated correctly
        let thumbnailData = try Data(contentsOf: thumbnailURL)
        let thumbnail = try #require(UIImage(data: thumbnailData), "Invalid thumbnail")
        
        #expect(thumbnail.size.width <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.width)
        #expect(thumbnail.size.height <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.height)
        
        // Check resulting video info
        #expect(videoInfo.mimetype == "video/mp4")
        #expect(videoInfo.blurhash == "KSB{R8O]MuwQS4oJvcaIt8")
        #expect(abs(Double(videoInfo.size ?? 0) - 5_824_946) <= 100)
        #expect(videoInfo.width == 1080)
        #expect(videoInfo.height == 1920)
        #expect(abs(Double(videoInfo.duration ?? 0) - 21) <= 100)
        
        #expect(videoInfo.thumbnailInfo != nil)
        #expect(videoInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(abs(Double(videoInfo.thumbnailInfo?.size ?? 0) - 40976) <= 100)
        #expect(videoInfo.thumbnailInfo?.width == 337)
        #expect(videoInfo.thumbnailInfo?.height == 600)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .video(optimizedVideoURL, _, optimizedVideoInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        #expect(optimizedVideoURL.pathExtension == "mp4", "The file extension should match the container we use.")
        
        // Check optimised video info
        #expect(optimizedVideoInfo.mimetype == "video/mp4")
        #expect(optimizedVideoInfo.blurhash == "KSC5.vO]MuwQS4oJvcaIt8")
        #expect(abs(Double(optimizedVideoInfo.size ?? 0) - 12_169_117) <= 100) // Note: This is slightly stupid because it is larger now 🤦‍♂️
        #expect(optimizedVideoInfo.width == 720)
        #expect(optimizedVideoInfo.height == 1280)
        #expect(abs(Double(optimizedVideoInfo.duration ?? 0) - 30) <= 100)
    }
    
    @Test
    func landscapeImageProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "landscape_test_image.jpg", withExtension: nil), "Failed retrieving test asset")
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(convertedImageURL, thumbnailURL, imageInfo) = result else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: convertedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check resulting image info
        #expect(imageInfo.mimetype == "image/jpeg")
        #expect(imageInfo.blurhash == "K%I#.NofkC_4ayayxujsWB")
        #expect(abs(Double(imageInfo.size ?? 0) - 3_305_795) <= 100)
        #expect(imageInfo.width == 6103)
        #expect(imageInfo.height == 2621)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(abs(Double(imageInfo.thumbnailInfo?.size ?? 0) - 87733) <= 100)
        #expect(imageInfo.thumbnailInfo?.width == 800)
        #expect(imageInfo.thumbnailInfo?.height == 344)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(optimizedImageURL, thumbnailURL, optimizedImageInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check optimised image info
        #expect(optimizedImageInfo.mimetype == "image/jpeg")
        #expect(optimizedImageInfo.blurhash == "K%I#.NofkC_4ayaxxujsWB")
        #expect(abs(Double(optimizedImageInfo.size ?? 0) - 524_226) <= 100)
        #expect(optimizedImageInfo.width == 2048)
        #expect(optimizedImageInfo.height == 879)
    }
    
    @Test
    func portraitImageProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "portrait_test_image.jpg", withExtension: nil), "Failed retrieving test asset")
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(convertedImageURL, thumbnailURL, imageInfo) = result else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: convertedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check resulting image info
        #expect(imageInfo.mimetype == "image/jpeg")
        #expect(imageInfo.blurhash == "KdE|0Ls+RP^-n*RP%OWAV@")
        #expect(abs(Double(imageInfo.size ?? 0) - 4_414_666) <= 100)
        #expect(imageInfo.width == 3024)
        #expect(imageInfo.height == 4032)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(abs(Double(imageInfo.thumbnailInfo?.size ?? 0) - 258_914) <= 100)
        #expect(imageInfo.thumbnailInfo?.width == 600)
        #expect(imageInfo.thumbnailInfo?.height == 800)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(optimizedImageURL, thumbnailURL, optimizedImageInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check optimised image info
        #expect(optimizedImageInfo.mimetype == "image/jpeg")
        #expect(optimizedImageInfo.blurhash == "KdE|0Ls+RP^-n*RP%OWAV@")
        #expect(abs(Double(optimizedImageInfo.size ?? 0) - 1_462_937) <= 100)
        #expect(optimizedImageInfo.width == 1536)
        #expect(optimizedImageInfo.height == 2048)
    }
    
    @Test
    func pngImageProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "test_image.png", withExtension: nil), "Failed retrieving test asset")
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(convertedImageURL, _, imageInfo) = result else {
            Issue.record("Failed processing asset")
            return
        }
        
        // Make sure the output file matches the image info.
        #expect(mimeType(from: convertedImageURL) == "image/png", "PNGs should always be sent as PNG to preserve the alpha channel.")
        #expect(convertedImageURL.pathExtension == "png", "The file extension should match the MIME type.")
        
        // Check resulting image info
        #expect(imageInfo.mimetype == "image/png")
        #expect(imageInfo.blurhash == "K0TSUA~qfQ~qj[fQfQfQfQ")
        #expect(abs(Double(imageInfo.size ?? 0) - 4868) <= 100)
        #expect(imageInfo.width == 240)
        #expect(imageInfo.height == 240)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(abs(Double(imageInfo.thumbnailInfo?.size ?? 0) - 1725) <= 100)
        #expect(imageInfo.thumbnailInfo?.width == 240)
        #expect(imageInfo.thumbnailInfo?.height == 240)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(optimizedImageURL, _, optimizedImageInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        // Make sure the output file matches the image info.
        #expect(mimeType(from: optimizedImageURL) == "image/png", "PNGs should always be sent as PNG to preserve the alpha channel.")
        #expect(optimizedImageURL.pathExtension == "png", "The file extension should match the MIME type.")
        
        // Check optimised image info
        #expect(optimizedImageInfo.mimetype == "image/png")
        #expect(optimizedImageInfo.blurhash == "K0TSUA~qfQ~qj[fQfQfQfQ")
        #expect(abs(Double(optimizedImageInfo.size ?? 0) - 8199) <= 100)
        // Assert that resizing didn't upscale to the maxPixelSize.
        #expect(optimizedImageInfo.width == 240)
        #expect(optimizedImageInfo.height == 240)
    }
    
    @Test
    func heicImageProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "test_apple_image.heic", withExtension: nil), "Failed retrieving test asset")
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(convertedImageURL, thumbnailURL, imageInfo) = result else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: convertedImageURL, withThumbnailAt: thumbnailURL)
        
        // Make sure the output file matches the image info.
        #expect(mimeType(from: convertedImageURL) == "image/heic", "Unoptimised HEICs should always be sent as is.")
        #expect(convertedImageURL.pathExtension == "heic", "The file extension should match the MIME type.")
        
        // Check resulting image info
        #expect(imageInfo.mimetype == "image/heic")
        #expect(imageInfo.blurhash == "KGD]3ns:T00$kWxFXmt6xv")
        #expect(abs(Double(imageInfo.size ?? 0) - 1_848_525) <= 100)
        #expect(imageInfo.width == 3024)
        #expect(imageInfo.height == 4032)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(abs(Double(imageInfo.thumbnailInfo?.size ?? 0) - 218_108) <= 100)
        #expect(imageInfo.thumbnailInfo?.width == 600)
        #expect(imageInfo.thumbnailInfo?.height == 800)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(optimizedImageURL, thumbnailURL, optimizedImageInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
        
        // Make sure the output file matches the image info.
        #expect(mimeType(from: optimizedImageURL) == "image/jpeg", "Optimised HEICs should always be converted to JPEG for compatibility.")
        #expect(optimizedImageURL.pathExtension == "jpeg", "The file extension should match the MIME type.")
        
        // Check optimised image info
        #expect(optimizedImageInfo.mimetype == "image/jpeg")
        #expect(optimizedImageInfo.blurhash == "KGD]3ns:T00#kWxFb^s:xv")
        #expect(abs(Double(optimizedImageInfo.size ?? 0) - 1_049_393) <= 100)
        #expect(optimizedImageInfo.width == 1536)
        #expect(optimizedImageInfo.height == 2048)
    }
    
    @Test
    func gifImageProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "test_animated_image.gif", withExtension: nil), "Failed retrieving test asset")
        let originalSizeValue = try FileManager.default.sizeForItem(at: url)
        let originalSize = try #require(originalSizeValue > 0 ? originalSizeValue : nil, "File size must be greater than zero")
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(convertedImageURL, _, imageInfo) = result else {
            Issue.record("Failed processing asset")
            return
        }
        
        // Make sure the output file matches the image info.
        #expect(mimeType(from: convertedImageURL) == "image/gif", "GIFs should always be sent as GIF to preserve the animation.")
        #expect(convertedImageURL.pathExtension == "gif", "The file extension should match the MIME type.")
        
        // Check resulting image info
        #expect(imageInfo.mimetype == "image/gif")
        #expect(imageInfo.blurhash == "KpRMPTj[_NxuaeRj%MofMx")
        #expect(abs(Double(imageInfo.size ?? 0) - Double(originalSize)) <= 100)
        #expect(imageInfo.width == 331)
        #expect(imageInfo.height == 472)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(abs(Double(imageInfo.thumbnailInfo?.size ?? 0) - 34215) <= 100)
        #expect(imageInfo.thumbnailInfo?.width == 331)
        #expect(imageInfo.thumbnailInfo?.height == 472)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(optimizedImageURL, _, optimizedImageInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        // Make sure the output file matches the image info.
        #expect(mimeType(from: optimizedImageURL) == "image/gif", "GIFs should always be sent as GIF to preserve the animation.")
        #expect(optimizedImageURL.pathExtension == "gif", "The file extension should match the MIME type.")
        
        // Ensure optimised image is still the same as the original image.
        #expect(optimizedImageInfo.mimetype == "image/gif")
        #expect(optimizedImageInfo.blurhash == "KpRMPTj[_NxuaeRj%MofMx")
        #expect(abs(Double(optimizedImageInfo.size ?? 0) - Double(originalSize)) <= 100)
        #expect(optimizedImageInfo.width == 331)
        #expect(optimizedImageInfo.height == 472)
    }
    
    @Test
    func rotatedImageProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "test_rotated_image.jpg", withExtension: nil), "Failed retrieving test asset")
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(convertedImageURL, thumbnailURL, imageInfo) = result else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: convertedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check resulting image info
        #expect(imageInfo.mimetype == "image/jpeg")
        #expect(imageInfo.width == 2848)
        #expect(imageInfo.height == 4272)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.width == 533)
        #expect(imageInfo.thumbnailInfo?.height == 800)
        
        // Repeat with optimised media setting
        appSettings.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(optimizedImageURL, thumbnailURL, optimizedImageInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check optimised image info
        #expect(optimizedImageInfo.mimetype == "image/jpeg")
        #expect(optimizedImageInfo.width == 1365)
        #expect(optimizedImageInfo.height == 2048)
    }
    
    // MARK: - Private
    
    private func compare(originalImageAt originalImageURL: URL, toConvertedImageAt convertedImageURL: URL, withThumbnailAt thumbnailURL: URL) throws {
        guard let originalImageData = try? Data(contentsOf: originalImageURL),
              let originalImage = UIImage(data: originalImageData),
              let convertedImageData = try? Data(contentsOf: convertedImageURL),
              let convertedImage = UIImage(data: convertedImageData) else {
            fatalError()
        }
        
        if appSettings.optimizeMediaUploads {
            // Check that new image has been scaled within the requirements for an optimised image
            #expect(convertedImage.size.width <= MediaUploadingPreprocessor.Constants.optimizedMaxPixelSize)
            #expect(convertedImage.size.height <= MediaUploadingPreprocessor.Constants.optimizedMaxPixelSize)
        } else {
            // Check that the file name is preserved
            #expect(originalImageURL.lastPathComponent == convertedImageURL.lastPathComponent)
            // Check that new image is the same size as the original one
            #expect(originalImage.size == convertedImage.size)
        }
        
        // Check that the GPS data has been stripped
        let originalMetadata = try metadata(from: originalImageData)
        #expect(originalMetadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") != nil)
        
        let convertedMetadata = try metadata(from: convertedImageData)
        #expect(convertedMetadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") == nil)
        
        // Check that the thumbnail is generated correctly
        let thumbnailData = try Data(contentsOf: thumbnailURL)
        let thumbnail = try #require(UIImage(data: thumbnailData), "Invalid thumbnail")
        
        if thumbnail.size.width > thumbnail.size.height {
            #expect(thumbnail.size.width <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.width)
            #expect(thumbnail.size.height <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.height)
        } else {
            #expect(thumbnail.size.width <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.height)
            #expect(thumbnail.size.height <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.width)
        }
        
        let thumbnailMetadata = try metadata(from: thumbnailData)
        #expect(thumbnailMetadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") == nil)
    }
    
    private func metadata(from imageData: Data) throws -> NSDictionary {
        let imageSource = try #require(CGImageSourceCreateWithData(imageData as NSData, nil), "Invalid asset")
        return try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary?, "Test asset is expected to contain metadata")
    }
    
    private func mimeType(from url: URL) -> String? {
        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
              let typeIdentifier = CGImageSourceGetType(imageSource),
              let type = UTType(typeIdentifier as String),
              let mimeType = type.preferredMIMEType else {
            Issue.record("Failed to get mimetype from URL.")
            return nil
        }
        return mimeType
    }
}
