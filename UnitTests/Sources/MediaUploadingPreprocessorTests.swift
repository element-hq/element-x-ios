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

final class MediaUploadingPreprocessorTests {
    let maxUploadSize: UInt = 100 * 1024 * 1024
    var userSettings: UserSettings!
    var mediaUploadingPreprocessor: MediaUploadingPreprocessor!
    
    init() {
        userSettings = UserSettings.mock()
        userSettings.app.optimizeMediaUploads = false
        mediaUploadingPreprocessor = MediaUploadingPreprocessor(userSettings: userSettings)
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
        #expect(isEqual(audioInfo.duration ?? 0, 10.03, within: 0.1))
        #expect(isEqual(audioInfo.size ?? 0, 194_811, within: 100))
    }
    
    @Test(.timeLimit(.minutes(2))) // Transcoding videos can be slow on a busy CI runner.
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
        #expect(isEqual(videoInfo.size ?? 0, 4_016_620, within: 100))
        #expect(videoInfo.width == 1280)
        #expect(videoInfo.height == 720)
        #expect(isEqual(videoInfo.duration ?? 0, 5.03, within: 0.1))
        
        #expect(videoInfo.thumbnailInfo != nil)
        #expect(videoInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(isEqual(videoInfo.thumbnailInfo?.size ?? 0, 183_093, within: 100))
        #expect(videoInfo.thumbnailInfo?.width == 800)
        #expect(videoInfo.thumbnailInfo?.height == 450)
    }
    
    @Test(.timeLimit(.minutes(2))) // Transcoding videos can be slow on a busy CI runner.
    func landscapeMovVideoOptimizedProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "landscape_test_video.mov", withExtension: nil), "Failed retrieving test asset")
        
        userSettings.app.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .video(optimizedVideoURL, _, optimizedVideoInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        #expect(optimizedVideoURL.pathExtension == "mp4", "The file extension should match the container we use.")
        
        // Check optimised video info
        #expect(optimizedVideoInfo.mimetype == "video/mp4")
        #expect(optimizedVideoInfo.blurhash == "K9F$LJZ9,+8yA9-:yT,@%1")
        #expect(isEqual(optimizedVideoInfo.size ?? 0, 4_016_620, within: 100)) // Note: The video is already 720p so it doesn't change size.
        #expect(optimizedVideoInfo.width == 1280)
        #expect(optimizedVideoInfo.height == 720)
        #expect(isEqual(optimizedVideoInfo.duration ?? 0, 5.03, within: 0.1))
    }
    
    @Test(.timeLimit(.minutes(2))) // Transcoding videos can be slow on a busy CI runner.
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
        #expect(videoInfo.blurhash == "KRB{K[TLMtw7S4oez,emtS")
        #expect(isEqual(videoInfo.size ?? 0, 2_004_280, within: 100))
        #expect(videoInfo.width == 1080)
        #expect(videoInfo.height == 1920)
        #expect(isEqual(videoInfo.duration ?? 0, 3.07, within: 0.1))
        
        #expect(videoInfo.thumbnailInfo != nil)
        #expect(videoInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(isEqual(videoInfo.thumbnailInfo?.size ?? 0, 40976, within: 100))
        #expect(videoInfo.thumbnailInfo?.width == 337)
        #expect(videoInfo.thumbnailInfo?.height == 600)
    }
    
    @Test(.timeLimit(.minutes(2))) // Transcoding videos can be slow on a busy CI runner.
    func portraitMp4VideoOptimizedProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "portrait_test_video.mp4", withExtension: nil), "Failed retrieving test asset")
        
        userSettings.app.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .video(optimizedVideoURL, _, optimizedVideoInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        #expect(optimizedVideoURL.pathExtension == "mp4", "The file extension should match the container we use.")
        
        // Check optimised video info
        #expect(optimizedVideoInfo.mimetype == "video/mp4")
        #expect(optimizedVideoInfo.blurhash == "KRB{K[TLMtw7S4oez,emtS")
        #expect(isEqual(optimizedVideoInfo.size ?? 0, 3_780_012, within: 100)) // Note: This is slightly stupid because it is larger now 🤦‍♂️
        #expect(optimizedVideoInfo.width == 720)
        #expect(optimizedVideoInfo.height == 1280)
        #expect(isEqual(optimizedVideoInfo.duration ?? 0, 3.07, within: 0.1))
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
        #expect(isEqual(imageInfo.size ?? 0, 3_305_795, within: 100))
        #expect(imageInfo.width == 6103)
        #expect(imageInfo.height == 2621)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(isEqual(imageInfo.thumbnailInfo?.size ?? 0, 87733, within: 100))
        #expect(imageInfo.thumbnailInfo?.width == 800)
        #expect(imageInfo.thumbnailInfo?.height == 344)
        
        // Repeat with optimised media setting
        userSettings.app.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(optimizedImageURL, thumbnailURL, optimizedImageInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check optimised image info
        #expect(optimizedImageInfo.mimetype == "image/jpeg")
        #expect(optimizedImageInfo.blurhash == "K%I#.NofkC_4ayaxxujsWB")
        #expect(isEqual(optimizedImageInfo.size ?? 0, 523_809, within: 100))
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
        #expect(isEqual(imageInfo.size ?? 0, 4_414_666, within: 100))
        #expect(imageInfo.width == 3024)
        #expect(imageInfo.height == 4032)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(isEqual(imageInfo.thumbnailInfo?.size ?? 0, 258_914, within: 100))
        #expect(imageInfo.thumbnailInfo?.width == 600)
        #expect(imageInfo.thumbnailInfo?.height == 800)
        
        // Repeat with optimised media setting
        userSettings.app.optimizeMediaUploads = true
        
        guard case let .success(optimizedResult) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(optimizedImageURL, thumbnailURL, optimizedImageInfo) = optimizedResult else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
        
        // Check optimised image info
        #expect(optimizedImageInfo.mimetype == "image/jpeg")
        #expect(optimizedImageInfo.blurhash == "KdE|0Ls+RP^-n*RP%OWAV@")
        #expect(isEqual(optimizedImageInfo.size ?? 0, 1_466_366, within: 100))
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
        #expect(isEqual(imageInfo.size ?? 0, 4868, within: 100))
        #expect(imageInfo.width == 240)
        #expect(imageInfo.height == 240)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(isEqual(imageInfo.thumbnailInfo?.size ?? 0, 1725, within: 100))
        #expect(imageInfo.thumbnailInfo?.width == 240)
        #expect(imageInfo.thumbnailInfo?.height == 240)
        
        // Repeat with optimised media setting
        userSettings.app.optimizeMediaUploads = true
        
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
        #expect(isEqual(optimizedImageInfo.size ?? 0, 8199, within: 100))
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
        #expect(isEqual(imageInfo.size ?? 0, 1_848_525, within: 100))
        #expect(imageInfo.width == 3024)
        #expect(imageInfo.height == 4032)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(isEqual(imageInfo.thumbnailInfo?.size ?? 0, 218_108, within: 100))
        #expect(imageInfo.thumbnailInfo?.width == 600)
        #expect(imageInfo.thumbnailInfo?.height == 800)
        
        // Repeat with optimised media setting
        userSettings.app.optimizeMediaUploads = true
        
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
        #expect(optimizedImageInfo.blurhash == "KGD]3ns:T00#kWxFXms:xv")
        #expect(isEqual(optimizedImageInfo.size ?? 0, 1_063_370, within: 100))
        #expect(optimizedImageInfo.width == 1536)
        #expect(optimizedImageInfo.height == 2048)
    }
    
    @Test
    func hdrImageProcessingStripsLocationFromImageAndGainMap() async throws {
        let imageSource = try await processedImageSource(at: makeHDRImageWithLocation())
        
        let metadata = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary?)
        #expect(metadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") == nil)
        
        let gainMapMetadata = try gainMapMetadata(from: imageSource)
        #expect(CGImageMetadataCopyTagWithPath(gainMapMetadata, nil, "exif:GPSLatitude" as CFString) == nil)
        #expect(CGImageMetadataCopyTagWithPath(gainMapMetadata, nil, "exif:GPSLongitude" as CFString) == nil)
    }
    
    @Test
    func hdrImageProcessingPreservesGainMap() async throws {
        let imageSource = try await processedImageSource(at: makeHDRImageWithLocation())
        
        let gainMapMetadata = try gainMapMetadata(from: imageSource)
        #expect(CGImageMetadataCopyTagWithPath(gainMapMetadata, nil, "HDRGainMap:HDRGainMapVersion" as CFString) != nil)
    }
    
    @Test
    func multiImageHDRProcessingKeepsGainMapOnItsImage() async throws {
        let imageSource = try await processedImageSource(at: makeHDRImageWithLocation(imageCount: 3))
        
        #expect(CGImageSourceGetCount(imageSource) == 3)
        #expect(CGImageSourceCopyAuxiliaryDataInfoAtIndex(imageSource, 0, kCGImageAuxiliaryDataTypeHDRGainMap) != nil)
        #expect(CGImageSourceCopyAuxiliaryDataInfoAtIndex(imageSource, 2, kCGImageAuxiliaryDataTypeHDRGainMap) == nil)
    }
    
    @Test
    func multiImageProcessingStripsLocationFoundOnlyOnLaterImage() async throws {
        let imageSource = try await processedImageSource(at: makeImageWithLocationOnSecondImage())
        
        #expect(CGImageSourceGetCount(imageSource) == 2)
        for index in 0..<CGImageSourceGetCount(imageSource) {
            let metadata = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as NSDictionary?)
            #expect(metadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") == nil)
        }
    }
    
    @Test
    func spatialImageProcessingKeepsStereoPair() async throws {
        let imageSource = try await processedImageSource(at: makeSpatialImageWithLocation())
        
        let group = try #require(stereoGroup(of: imageSource))
        #expect(group[kCGImagePropertyGroupImageIndexMonoscopic] as? Int == 0)
        #expect(group[kCGImagePropertyGroupImageIndexRight] as? Int == 1)
        #expect(group[kCGImagePropertyGroupImageIndexLeft] as? Int == 2)
        #expect(group[kCGImagePropertyGroupImageDisparityAdjustment] as? Int == 800)
        #expect(group[kCGImagePropertyGroupMonoscopicImageLocation] as? String == kIIOMonoscopicImageLocation_Right as String)
    }
    
    @Test
    func spatialImageProcessingKeepsEyeCameras() async throws {
        let imageSource = try await processedImageSource(at: makeSpatialImageWithLocation())
        
        for eyeIndex in [1, 2] {
            let properties = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, eyeIndex, nil) as? [CFString: Any])
            let camera = properties[kCGImagePropertyHEIFDictionary] as? [CFString: Any]
            #expect(camera?[kIIOMetadata_CameraExtrinsicsKey] != nil)
            #expect(camera?[kIIOMetadata_CameraModelKey] != nil)
        }
    }
    
    @Test
    func spatialImageProcessingStripsLocationFromEveryImage() async throws {
        let imageSource = try await processedImageSource(at: makeSpatialImageWithLocation())
        
        #expect(CGImageSourceGetCount(imageSource) == 3)
        for index in 0..<CGImageSourceGetCount(imageSource) {
            let metadata = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as NSDictionary?)
            #expect(metadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") == nil)
        }
    }
    
    @Test
    func spatialImageProcessingKeepsGainMapOnEachImage() async throws {
        let url = try makeSpatialImageWithLocation()
        let originalSource = try #require(CGImageSourceCreateWithURL(url as NSURL, nil))
        
        let imageSource = try await processedImageSource(at: url)
        
        for index in 0..<CGImageSourceGetCount(originalSource) {
            #expect(gainMapWidth(of: imageSource, at: index) == gainMapWidth(of: originalSource, at: index))
        }
    }
    
    @Test
    func optimisedImageProcessingSkipsStrippingLocation() async throws {
        // A read-only image can't be rewritten in place, so it can only be processed when the strip is skipped.
        let url = try copyResourceToTemporaryDirectory("landscape_test_image.jpg")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        try FileManager.default.setAttributes([.posixPermissions: 0o444], ofItemAtPath: url.path(percentEncoded: false))
        
        guard case .failure(.failedProcessingImage(.failedStrippingLocationData)) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize) else {
            Issue.record("Expected stripping the location to fail")
            return
        }
        
        userSettings.app.optimizeMediaUploads = true
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize),
              case let .image(optimizedImageURL, thumbnailURL, _) = result else {
            Issue.record("Failed processing asset")
            return
        }
        
        try compare(originalImageAt: url, toConvertedImageAt: optimizedImageURL, withThumbnailAt: thumbnailURL)
    }
    
    @Test
    func gifImageProcessing() async throws {
        let url = try #require(Bundle(for: Self.self).url(forResource: "test_animated_image.gif", withExtension: nil), "Failed retrieving test asset")
        let originalSizeValue = try UInt64(FileManager.default.sizeForItem(at: url))
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
        #expect(isEqual(imageInfo.size ?? 0, originalSize, within: 100))
        #expect(imageInfo.width == 331)
        #expect(imageInfo.height == 472)
        
        #expect(imageInfo.thumbnailInfo != nil)
        #expect(imageInfo.thumbnailInfo?.mimetype == "image/jpeg")
        #expect(isEqual(imageInfo.thumbnailInfo?.size ?? 0, 34215, within: 100))
        #expect(imageInfo.thumbnailInfo?.width == 331)
        #expect(imageInfo.thumbnailInfo?.height == 472)
        
        // Repeat with optimised media setting
        userSettings.app.optimizeMediaUploads = true
        
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
        #expect(isEqual(optimizedImageInfo.size ?? 0, originalSize, within: 100))
        #expect(optimizedImageInfo.width == 331)
        #expect(optimizedImageInfo.height == 472)
    }
    
    @Test
    func animatedGIFWithLocationProcessingKeepsAllFrames() async throws {
        let url = try makeAnimatedGIFWithLocation(loopCount: 3)
        let originalSource = try #require(CGImageSourceCreateWithURL(url as NSURL, nil))
        
        let imageSource = try await processedImageSource(at: url)
        
        #expect(CGImageSourceGetCount(imageSource) == CGImageSourceGetCount(originalSource))
        #expect(gifProperties(of: imageSource)?[kCGImagePropertyGIFLoopCount] as? Int == 3)
        
        for index in 0..<CGImageSourceGetCount(imageSource) {
            let metadata = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil) as NSDictionary?)
            #expect(metadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") == nil)
            #expect(gifProperties(of: imageSource, at: index)?[kCGImagePropertyGIFDelayTime] as? Double ==
                gifProperties(of: originalSource, at: index)?[kCGImagePropertyGIFDelayTime] as? Double)
        }
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
        userSettings.app.optimizeMediaUploads = true
        
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
    
    @Test
    func batchPreservesInputOrderBeyondConcurrencyLimit() async throws {
        let names = ["test_image.png", "test_animated_image.gif", "landscape_test_image.jpg"]
        try #require(names.count > MediaUploadingPreprocessor.Constants.maximumConcurrentProcessingCount)
        let inputs = try names.map { try #require(Bundle(for: Self.self).url(forResource: $0, withExtension: nil)) }
        let results = try await mediaUploadingPreprocessor.processMedia(at: inputs, maxUploadSize: maxUploadSize).get()
        defer {
            for result in results {
                try? FileManager.default.removeItem(at: result.url.deletingLastPathComponent())
            }
        }
        #expect(results.map(\.url.lastPathComponent) == names)
        for result in results {
            let thumbnailURL = try #require(result.thumbnailURL)
            #expect(try Data(contentsOf: result.url).isEmpty == false)
            #expect(try Data(contentsOf: thumbnailURL).isEmpty == false)
        }
    }
    
    @Test
    func failedPreparationRemovesItsFiles() async throws {
        let url = try copyResourceToTemporaryDirectory("test_image.png")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        
        guard case .failure(.maxUploadSizeExceeded) = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: 1) else {
            Issue.record("Expected the upload size to be exceeded")
            return
        }
        #expect(try preparedFolders(for: url).isEmpty)
    }
    
    @Test
    func batchFailureReturnsTheErrorAndRemovesPreparedFiles() async throws {
        let url = try copyResourceToTemporaryDirectory("test_image.png")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        let missingURL = url.deletingLastPathComponent().appendingPathComponent("missing.png")
        
        // The missing file comes last so that at least one image has already been prepared when the batch fails.
        guard case .failure(.failedProcessingMedia) = await mediaUploadingPreprocessor.processMedia(at: [url, url, missingURL], maxUploadSize: maxUploadSize) else {
            Issue.record("Expected the missing file to fail the batch")
            return
        }
        #expect(try preparedFolders(for: url).isEmpty)
    }
    
    @Test
    func cancellationRemovesPreparedFiles() async throws {
        let url = try copyResourceToTemporaryDirectory("test_image.png")
        defer { try? FileManager.default.removeItem(at: url.deletingLastPathComponent()) }
        
        let task = Task { await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize) }
        await Task.yield() // Let the preparation start.
        task.cancel()
        
        guard case .failure(.cancelled) = await task.value else {
            Issue.record("Expected the preparation to be cancelled")
            return
        }
        #expect(try preparedFolders(for: url).isEmpty)
    }
    
    // MARK: - Private
    
    /// Copies a test asset to a uniquely named file, so the folders the preprocessor prepares from it can be found afterwards.
    private func copyResourceToTemporaryDirectory(_ resource: String) throws -> URL {
        let assetURL = try #require(Bundle(for: Self.self).url(forResource: resource, withExtension: nil))
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("\(Self.self)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("\(UUID().uuidString).\(assetURL.pathExtension)")
        try FileManager.default.copyItem(at: assetURL, to: url)
        return url
    }
    
    /// Processes the image at the given URL, returning a source for the resulting image.
    private func processedImageSource(at url: URL) async throws -> CGImageSource {
        let mediaInfo = try await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize).get()
        return try #require(CGImageSourceCreateWithURL(mediaInfo.url as NSURL, nil))
    }
    
    private func gainMapMetadata(from imageSource: CGImageSource) throws -> CGImageMetadata {
        let gainMapInfo = try #require(CGImageSourceCopyAuxiliaryDataInfoAtIndex(imageSource, 0, kCGImageAuxiliaryDataTypeHDRGainMap) as? [CFString: Any])
        let gainMapMetadata = try #require(gainMapInfo[kCGImageAuxiliaryDataInfoMetadata])
        // swiftlint:disable:next force_cast
        return gainMapMetadata as! CGImageMetadata
    }
    
    /// Generates a HEIC with an HDR gain map on its first image and GPS metadata (on both the images and the gain map) in a unique temporary directory.
    private func makeHDRImageWithLocation(imageCount: Int = 1) throws -> URL {
        let image = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 64, height: 64))
        let gainMap = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 32, height: 32))
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.displayP3))
        let hdrData = try #require(CIContext().heifRepresentation(of: image, format: .RGBA8, colorSpace: colorSpace, options: [.hdrGainMapImage: gainMap]))
        let hdrSource = try #require(CGImageSourceCreateWithData(hdrData as NSData, nil))
        var gainMapInfo = try #require(CGImageSourceCopyAuxiliaryDataInfoAtIndex(hdrSource, 0, kCGImageAuxiliaryDataTypeHDRGainMap) as? [CFString: Any])
        let gainMapMetadataWithLocation = try #require(CGImageMetadataCreateMutableCopy(gainMapMetadata(from: hdrSource)))
        try #require(CGImageMetadataSetValueWithPath(gainMapMetadataWithLocation, nil, "exif:GPSLatitude" as CFString, "51,30.0N" as CFString))
        try #require(CGImageMetadataSetValueWithPath(gainMapMetadataWithLocation, nil, "exif:GPSLongitude" as CFString, "0,6.0W" as CFString))
        gainMapInfo[kCGImageAuxiliaryDataInfoMetadata] = gainMapMetadataWithLocation
        
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("\(Self.self)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("hdr_test_image.heic")
        
        let destination = try #require(CGImageDestinationCreateWithURL(url as NSURL, UTType.heic.identifier as CFString, imageCount, nil))
        let location = [kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 51.5, kCGImagePropertyGPSLongitude: 0.1]]
        CGImageDestinationAddImageFromSource(destination, hdrSource, 0, location as NSDictionary)
        CGImageDestinationAddAuxiliaryDataInfo(destination, kCGImageAuxiliaryDataTypeHDRGainMap, gainMapInfo as NSDictionary)
        for _ in 1..<imageCount {
            CGImageDestinationAddImageFromSource(destination, hdrSource, 0, location as NSDictionary)
        }
        try #require(CGImageDestinationFinalize(destination))
        
        // Without location data the preprocessor leaves the image untouched.
        let imageSource = try #require(CGImageSourceCreateWithURL(url as NSURL, nil))
        let metadata = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary?)
        try #require(metadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") != nil)
        try #require(CGImageMetadataCopyTagWithPath(gainMapMetadata(from: imageSource), nil, "exif:GPSLatitude" as CFString) != nil)
        
        return url
    }
    
    /// Generates a two image HEIC with GPS metadata on its second image only in a unique temporary directory.
    private func makeImageWithLocationOnSecondImage() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("\(Self.self)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("second_image_location_test_image.heic")
        
        let extent = CGRect(x: 0, y: 0, width: 64, height: 64)
        let image = try #require(CIContext().createCGImage(CIImage(color: .gray).cropped(to: extent), from: extent))
        let destination = try #require(CGImageDestinationCreateWithURL(url as NSURL, UTType.heic.identifier as CFString, 2, nil))
        CGImageDestinationAddImage(destination, image, nil)
        let location = [kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 51.5, kCGImagePropertyGPSLongitude: 0.1]]
        CGImageDestinationAddImage(destination, image, location as NSDictionary)
        try #require(CGImageDestinationFinalize(destination))
        
        let imageSource = try #require(CGImageSourceCreateWithURL(url as NSURL, nil))
        let firstMetadata = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) as NSDictionary?)
        let secondMetadata = try #require(CGImageSourceCopyPropertiesAtIndex(imageSource, 1, nil) as NSDictionary?)
        try #require(firstMetadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") == nil)
        try #require(secondMetadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") != nil)
        
        return url
    }
    
    /// Generates a HEIC laid out like an iPhone spatial photo in a unique temporary directory: a monoscopic primary image, then the right and
    /// left eyes, all in one stereo pair group. Every image has GPS metadata and an HDR gain map of its own size, and each eye has its camera.
    private func makeSpatialImageWithLocation() throws -> URL {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("\(Self.self)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("spatial_test_image.heic")
        
        let roles = [kCGImagePropertyGroupImageIsMonoscopicImage, kCGImagePropertyGroupImageIsRightImage, kCGImagePropertyGroupImageIsLeftImage]
        let destination = try #require(CGImageDestinationCreateWithURL(url as NSURL, UTType.heic.identifier as CFString, roles.count, nil))
        let colorSpace = try #require(CGColorSpace(name: CGColorSpace.displayP3))
        
        for (index, role) in roles.enumerated() {
            let image = CIImage(color: .gray).cropped(to: CGRect(x: 0, y: 0, width: 64, height: 64))
            let gainMap = CIImage(color: .white).cropped(to: CGRect(x: 0, y: 0, width: 16 + 8 * index, height: 16 + 8 * index))
            let hdrData = try #require(CIContext().heifRepresentation(of: image, format: .RGBA8, colorSpace: colorSpace, options: [.hdrGainMapImage: gainMap]))
            let hdrSource = try #require(CGImageSourceCreateWithData(hdrData as NSData, nil))
            let gainMapInfo = try #require(CGImageSourceCopyAuxiliaryDataInfoAtIndex(hdrSource, 0, kCGImageAuxiliaryDataTypeHDRGainMap))
            
            var properties: [CFString: Any] = [kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 51.5, kCGImagePropertyGPSLongitude: 0.1],
                                               kCGImagePropertyGroups: [kCGImagePropertyGroupIndex: 0,
                                                                        kCGImagePropertyGroupType: kCGImagePropertyGroupTypeStereoPair,
                                                                        kCGImagePropertyGroupImageDisparityAdjustment: 800,
                                                                        kCGImagePropertyGroupMonoscopicImageLocation: kIIOMonoscopicImageLocation_Right,
                                                                        role: true]]
            if role != kCGImagePropertyGroupImageIsMonoscopicImage {
                properties[kCGImagePropertyHEIFDictionary] = [kIIOMetadata_CameraExtrinsicsKey: [kIIOCameraExtrinsics_Position: [0.0, 0.0, 0.0],
                                                                                                 kIIOCameraExtrinsics_Rotation: [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0]],
                                                              kIIOMetadata_CameraModelKey: [kIIOCameraModel_Intrinsics: [1000.0, 0.0, 32.0, 0.0, 1000.0, 32.0, 0.0, 0.0, 1.0]]]
            }
            CGImageDestinationAddImageFromSource(destination, hdrSource, 0, properties as NSDictionary)
            CGImageDestinationAddAuxiliaryDataInfo(destination, kCGImageAuxiliaryDataTypeHDRGainMap, gainMapInfo)
        }
        try #require(CGImageDestinationFinalize(destination))
        
        let imageSource = try #require(CGImageSourceCreateWithURL(url as NSURL, nil))
        try #require(stereoGroup(of: imageSource) != nil)
        
        return url
    }
    
    /// The stereo pair group of a spatial photo, which ImageIO reports on the whole image rather than on each of its images.
    private func stereoGroup(of imageSource: CGImageSource) -> [CFString: Any]? {
        let groups = (CGImageSourceCopyProperties(imageSource, nil) as? [CFString: Any])?[kCGImagePropertyGroups] as? [[CFString: Any]]
        return groups?.first { $0[kCGImagePropertyGroupType] as? String == kCGImagePropertyGroupTypeStereoPair as String }
    }
    
    private func gainMapWidth(of imageSource: CGImageSource, at index: Int) -> Int? {
        let gainMapInfo = CGImageSourceCopyAuxiliaryDataInfoAtIndex(imageSource, index, kCGImageAuxiliaryDataTypeHDRGainMap) as? [CFString: Any]
        let description = gainMapInfo?[kCGImageAuxiliaryDataInfoDataDescription] as? [String: Any]
        return description?["Width"] as? Int
    }
    
    /// Generates a copy of the animated test GIF with GPS metadata on every frame in a unique temporary directory.
    private func makeAnimatedGIFWithLocation(loopCount: Int) throws -> URL {
        let assetURL = try #require(Bundle(for: Self.self).url(forResource: "test_animated_image.gif", withExtension: nil))
        let gifSource = try #require(CGImageSourceCreateWithURL(assetURL as NSURL, nil))
        let frameCount = CGImageSourceGetCount(gifSource)
        try #require(frameCount > 1)
        
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("\(Self.self)-\(UUID().uuidString)")
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let url = directory.appendingPathComponent("gif_test_image.gif")
        
        let destination = try #require(CGImageDestinationCreateWithURL(url as NSURL, UTType.gif.identifier as CFString, frameCount, nil))
        CGImageDestinationSetProperties(destination, [kCGImagePropertyGIFDictionary: [kCGImagePropertyGIFLoopCount: loopCount]] as NSDictionary)
        let location = [kCGImagePropertyGPSDictionary: [kCGImagePropertyGPSLatitude: 51.5, kCGImagePropertyGPSLongitude: 0.1]]
        for index in 0..<frameCount {
            CGImageDestinationAddImageFromSource(destination, gifSource, index, location as NSDictionary)
        }
        try #require(CGImageDestinationFinalize(destination))
        
        // Without location data the preprocessor leaves the image untouched.
        let metadata = try metadata(from: Data(contentsOf: url))
        try #require(metadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") != nil)
        
        return url
    }
    
    /// The GIF properties of the whole image, or of the frame at the given index.
    private func gifProperties(of imageSource: CGImageSource, at index: Int? = nil) -> [CFString: Any]? {
        let properties = if let index {
            CGImageSourceCopyPropertiesAtIndex(imageSource, index, nil)
        } else {
            CGImageSourceCopyProperties(imageSource, nil)
        }
        return (properties as? [CFString: Any])?[kCGImagePropertyGIFDictionary] as? [CFString: Any]
    }
    
    /// The unique folders created by the preprocessor for the given file that still exist.
    private func preparedFolders(for url: URL) throws -> [URL] {
        let name = url.deletingPathExtension().lastPathComponent
        return try FileManager.default.contentsOfDirectory(at: FileManager.default.temporaryDirectory, includingPropertiesForKeys: nil)
            .filter { UUID(uuidString: $0.lastPathComponent) != nil }
            .filter { folder in
                let contents = (try? FileManager.default.contentsOfDirectory(atPath: folder.path(percentEncoded: false))) ?? []
                return contents.contains { $0.contains(name) }
            }
    }
    
    private func isEqual<N: UnsignedInteger>(_ lhs: N, _ rhs: N, within tolerance: N) -> Bool {
        isEqual(Double(lhs), Double(rhs), within: Double(tolerance))
    }
    
    private func isEqual<N: SignedNumeric & Comparable>(_ lhs: N, _ rhs: N, within tolerance: N) -> Bool {
        abs(lhs - rhs) <= tolerance
    }
    
    private func compare(originalImageAt originalImageURL: URL, toConvertedImageAt convertedImageURL: URL, withThumbnailAt thumbnailURL: URL) throws {
        guard let originalImageData = try? Data(contentsOf: originalImageURL),
              let originalImage = UIImage(data: originalImageData),
              let convertedImageData = try? Data(contentsOf: convertedImageURL),
              let convertedImage = UIImage(data: convertedImageData) else {
            fatalError()
        }
        
        if userSettings.app.optimizeMediaUploads {
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
