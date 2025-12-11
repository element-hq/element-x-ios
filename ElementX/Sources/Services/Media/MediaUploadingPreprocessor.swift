//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVFoundation
import MatrixRustSDK
import UIKit
import UniformTypeIdentifiers

indirect enum MediaUploadingPreprocessorError: Error {
    case maxUploadSizeUnknown
    case maxUploadSizeExceeded(limit: UInt)
    
    case failedProcessingMedia(Error)
    
    case failedProcessingImage(MediaUploadingPreprocessorError)
    case failedProcessingVideo(MediaUploadingPreprocessorError)
    case failedProcessingAudio
    
    case failedGeneratingVideoThumbnail(Error?)
    case failedGeneratingImageThumbnail(Error?)
    
    case failedStrippingLocationData
    case failedResizingImage
    
    case failedConvertingVideo
}

enum MediaInfo {
    case image(imageURL: URL, thumbnailURL: URL, imageInfo: ImageInfo)
    case video(videoURL: URL, thumbnailURL: URL, videoInfo: VideoInfo)
    case audio(audioURL: URL, audioInfo: AudioInfo)
    case file(fileURL: URL, fileInfo: FileInfo)
    
    var mimeType: String? {
        switch self {
        case .image(_, _, let imageInfo):
            return imageInfo.mimetype
        case .video(_, _, let videoInfo):
            return videoInfo.mimetype
        case .audio(_, let audioInfo):
            return audioInfo.mimetype
        case .file(_, let fileInfo):
            return fileInfo.mimetype
        }
    }
    
    var url: URL {
        switch self {
        case .image(let url, _, _),
             .video(let url, _, _),
             .audio(let url, _),
             .file(let url, _):
            return url
        }
    }
    
    var thumbnailURL: URL? {
        switch self {
        case .image(_, let url, _), .video(_, let url, _):
            return url
        case .audio, .file:
            return nil
        }
    }
}

private struct ImageProcessingInfo {
    let url: URL
    let height: Double
    let width: Double
    let mimeType: String
    let blurhash: String?
}

private struct VideoProcessingInfo {
    let url: URL
    let height: Double
    let width: Double
    let duration: Double // seconds
    let mimeType: String
}

struct MediaUploadingPreprocessor {
    let appSettings: AppSettings
    
    enum Constants {
        static let maximumThumbnailSize = CGSize(width: 800, height: 600)
        static let optimizedMaxPixelSize = 2048.0
        static let jpegCompressionQuality = 0.78
        static let videoThumbnailTime = 5.0 // seconds
    }
    
    /// Processes media at the given URLs. It will generate thumbnails for images and videos, convert videos to 1080p mp4, strip GPS locations
    /// from images and retrieve associated media information
    /// - Parameter urls: the file URL
    /// - Returns: a collection of results containing specific type of `MediaInfo` depending on the file type
    /// and its associated details or any resulting error
    func processMedia(at urls: [URL], maxUploadSize: UInt) async -> Result<[MediaInfo], MediaUploadingPreprocessorError> {
        await withTaskGroup { taskGroup in
            for (index, url) in urls.enumerated() {
                taskGroup.addTask {
                    let result = await processMedia(at: url, maxUploadSize: maxUploadSize)
                    return (index, result)
                }
            }
            
            // Store results in their respective index as they come in
            var results = [MediaInfo?](repeating: nil, count: urls.count)
            
            for await (index, result) in taskGroup {
                switch result {
                case .success(let mediaInfo):
                    results[index] = mediaInfo
                case .failure(let error):
                    return .failure(error)
                }
            }
            
            return .success(results.compactMap { $0 })
        }
    }
    
    /// Processes media at a given URL. It will generate thumbnails for images and videos, convert videos to 1080p mp4, strip GPS locations
    /// from images and retrieve associated media information
    /// - Parameter url: the file URL
    /// - Returns: a specific type of `MediaInfo` depending on the file type and its associated details
    func processMedia(at url: URL, maxUploadSize: UInt) async -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        // Start by copying the file to a unique temporary location in order to avoid conflicts if processing it multiple times
        // All the other operations will be made relative to it
        let uniqueFolder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        var newURL = uniqueFolder.appendingPathComponent(url.lastPathComponent)
        do {
            try FileManager.default.createDirectory(at: uniqueFolder, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: url, to: newURL)
        } catch {
            return .failure(.failedProcessingMedia(error))
        }
        
        // Process unknown types as plain files
        guard let type = UTType(filenameExtension: newURL.pathExtension),
              let mimeType = type.preferredMIMEType else {
            return processFile(at: newURL, mimeType: "application/octet-stream", maxUploadSize: maxUploadSize)
        }
        
        if type.conforms(to: .image) {
            return processImage(at: &newURL, type: type, mimeType: mimeType, maxUploadSize: maxUploadSize)
        } else if type.conforms(to: .movie) || type.conforms(to: .video) {
            return await processVideo(at: newURL, maxUploadSize: maxUploadSize)
        } else if type.conforms(to: .audio) {
            return await processAudio(at: newURL, mimeType: mimeType, maxUploadSize: maxUploadSize)
        } else {
            return processFile(at: newURL, mimeType: mimeType, maxUploadSize: maxUploadSize)
        }
    }
    
    // MARK: - Private
    
    /// Prepares an image for upload. Strips location data from it and generates a thumbnail
    /// - Parameters:
    ///   - url: The image URL
    ///   - type: its UTType
    ///   - mimeType: the mimeType extracted from the UTType
    /// - Returns: Returns a `MediaInfo.image` containing the URLs for the modified image and its thumbnail plus the corresponding `ImageInfo`
    private func processImage(at url: inout URL, type: UTType, mimeType: String, maxUploadSize: UInt) -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        do {
            try stripLocationFromImage(at: url, type: type)
            
            var mimeType = mimeType
            if appSettings.optimizeMediaUploads, !type.conforms(to: .gif) {
                let outputType = type.conforms(to: .png) ? UTType.png : .jpeg
                mimeType = outputType.preferredMIMEType ?? "application/octet-stream"
                try resizeImage(at: url, maxPixelSize: Constants.optimizedMaxPixelSize, destination: url, type: outputType)
                
                if let preferredFilenameExtension = outputType.preferredFilenameExtension,
                   url.pathExtension != preferredFilenameExtension {
                    let convertedURL = url.deletingPathExtension().appendingPathExtension(preferredFilenameExtension)
                    do {
                        try FileManager.default.moveItem(at: url, to: convertedURL)
                    } catch {
                        return .failure(.failedResizingImage)
                    }
                    url = convertedURL
                }
            }
            
            let thumbnailResult = try generateThumbnailForImage(at: url)
            
            guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil),
                  let imageSize = imageSource.size else {
                return .failure(.failedProcessingImage(.failedStrippingLocationData))
            }
            
            let fileSize = (try? FileManager.default.sizeForItem(at: url)) ?? 0
            let thumbnailFileSize = (try? FileManager.default.sizeForItem(at: thumbnailResult.url)) ?? 0
            
            guard fileSize < maxUploadSize, thumbnailFileSize < maxUploadSize else { return .failure(.maxUploadSizeExceeded(limit: maxUploadSize)) }
            
            let thumbnailInfo = ThumbnailInfo(height: UInt64(thumbnailResult.height),
                                              width: UInt64(thumbnailResult.width),
                                              mimetype: thumbnailResult.mimeType,
                                              size: UInt64(thumbnailFileSize))
            
            let imageInfo = ImageInfo(height: UInt64(imageSize.height),
                                      width: UInt64(imageSize.width),
                                      mimetype: mimeType,
                                      size: UInt64(fileSize),
                                      thumbnailInfo: thumbnailInfo,
                                      thumbnailSource: nil,
                                      blurhash: thumbnailResult.blurhash,
                                      isAnimated: nil)
            
            let mediaInfo = MediaInfo.image(imageURL: url, thumbnailURL: thumbnailResult.url, imageInfo: imageInfo)
            
            return .success(mediaInfo)
        } catch {
            return .failure(.failedProcessingImage(error))
        }
    }
    
    /// Prepares a video for upload. Converts it to an 1080p mp4 and generates a thumbnail
    /// - Parameters:
    ///   - url: The video URL
    ///   - type: its UTType
    ///   - mimeType: the mimeType extracted from the UTType
    /// - Returns: Returns a `MediaInfo.video` containing the URLs for the modified video and its thumbnail plus the corresponding `VideoInfo`
    private func processVideo(at url: URL, maxUploadSize: UInt) async -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        do {
            let result = try await convertVideoToMP4(url, targetFileSize: UInt(maxUploadSize))
            let thumbnailResult = try await generateThumbnailForVideoAt(result.url)
            
            let videoSize = (try? FileManager.default.sizeForItem(at: result.url)) ?? 0
            let thumbnailSize = (try? FileManager.default.sizeForItem(at: thumbnailResult.url)) ?? 0
            
            guard videoSize < maxUploadSize, thumbnailSize < maxUploadSize else { return .failure(.maxUploadSizeExceeded(limit: maxUploadSize)) }
            
            let thumbnailInfo = ThumbnailInfo(height: UInt64(thumbnailResult.height),
                                              width: UInt64(thumbnailResult.width),
                                              mimetype: thumbnailResult.mimeType,
                                              size: UInt64(thumbnailSize))
            
            let videoInfo = VideoInfo(duration: result.duration,
                                      height: UInt64(result.height),
                                      width: UInt64(result.width),
                                      mimetype: result.mimeType,
                                      size: UInt64(videoSize),
                                      thumbnailInfo: thumbnailInfo,
                                      thumbnailSource: nil,
                                      blurhash: thumbnailResult.blurhash)
            
            let mediaInfo = MediaInfo.video(videoURL: result.url, thumbnailURL: thumbnailResult.url, videoInfo: videoInfo)
            
            return .success(mediaInfo)
        } catch {
            return .failure(.failedProcessingVideo(error))
        }
    }
    
    /// Prepares a file for upload.
    /// - Parameters:
    ///   - url: The audio URL
    ///   - mimeType: the mimeType extracted from the UTType
    /// - Returns: Returns a `MediaInfo.audio` containing the file URL plus the corresponding `AudioInfo`
    private func processAudio(at url: URL, mimeType: String?, maxUploadSize: UInt) async -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        let fileSize = (try? FileManager.default.sizeForItem(at: url)) ?? 0
        
        guard fileSize < maxUploadSize else { return .failure(.maxUploadSizeExceeded(limit: maxUploadSize)) }
        
        let asset = AVURLAsset(url: url)
        guard let durationInSeconds = try? await asset.load(.duration).seconds else {
            return .failure(.failedProcessingAudio)
        }
        
        let audioInfo = AudioInfo(duration: durationInSeconds, size: UInt64(fileSize), mimetype: mimeType)
        return .success(.audio(audioURL: url, audioInfo: audioInfo))
    }
    
    /// Prepares a file for upload.
    /// - Parameters:
    ///   - url: The file URL
    ///   - type: its UTType
    ///   - mimeType: the mimeType extracted from the UTType
    /// - Returns: Returns a `MediaInfo.file` containing the file URL plus the corresponding `FileInfo`
    private func processFile(at url: URL, mimeType: String?, maxUploadSize: UInt) -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        let fileSize = (try? FileManager.default.sizeForItem(at: url)) ?? 0
        
        guard fileSize < maxUploadSize else { return .failure(.maxUploadSizeExceeded(limit: maxUploadSize)) }
        
        let fileInfo = FileInfo(mimetype: mimeType, size: UInt64(fileSize), thumbnailInfo: nil, thumbnailSource: nil)
        return .success(.file(fileURL: url, fileInfo: fileInfo))
    }
    
    // MARK: Image Helpers
    
    /// Removes the GPS dictionary from an image's metadata
    /// - Parameters:
    ///   - url: the URL for the original image
    ///   - type: its UTType
    /// - Returns: the URL for the modified image and its size as an `ImageProcessingResult`
    private func stripLocationFromImage(at url: URL, type: UTType) throws(MediaUploadingPreprocessorError) {
        guard let originalData = NSData(contentsOf: url),
              let imageSource = CGImageSourceCreateWithData(originalData, nil) else {
            throw .failedStrippingLocationData
        }
        
        guard let originalMetadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil),
              (originalMetadata as NSDictionary).value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") != nil else {
            MXLog.info("No GPS metadata found. Nothing to do.")
            return
        }
        
        let count = CGImageSourceGetCount(imageSource)
        let metadataKeysToRemove = [kCGImagePropertyGPSDictionary: kCFNull]
        
        let data = NSMutableData()
        
        // Certain type identifiers cannot be used for image destinations, fall
        // back to `public.jpeg` when that's the case
        let destination = CGImageDestinationCreateWithData(data as CFMutableData, type.identifier as CFString, count, nil) ??
            CGImageDestinationCreateWithData(data as CFMutableData, UTType.jpeg.identifier as CFString, count, nil)
        guard let destination else {
            throw .failedStrippingLocationData
        }
        
        CGImageDestinationAddImageFromSource(destination, imageSource, 0, metadataKeysToRemove as NSDictionary)
        CGImageDestinationFinalize(destination)
        
        do {
            try data.write(to: url)
        } catch {
            throw .failedStrippingLocationData
        }
    }
    
    /// Generates a thumbnail for an image
    /// - Parameter url: the original image URL
    /// - Returns: the URL for the resulting thumbnail and its sizing info as an `ImageProcessingResult`
    private func generateThumbnailForImage(at url: URL) throws(MediaUploadingPreprocessorError) -> ImageProcessingInfo {
        let thumbnailFileName = "thumbnail-\((url.lastPathComponent as NSString).deletingPathExtension).jpeg"
        let thumbnailURL = url.deletingLastPathComponent().appendingPathComponent(thumbnailFileName)
        let thumbnailMaxPixelSize = max(Constants.maximumThumbnailSize.height, Constants.maximumThumbnailSize.width)
        
        do {
            try resizeImage(at: url, maxPixelSize: thumbnailMaxPixelSize, destination: thumbnailURL, type: .jpeg)
        } catch {
            throw .failedGeneratingImageThumbnail(error)
        }
        
        guard let thumbnail = try? UIImage(contentsOf: thumbnailURL, cachePolicy: .useProtocolCachePolicy) else {
            throw .failedGeneratingImageThumbnail(nil)
        }
        let blurhash = thumbnail.blurHash(numberOfComponents: (3, 3))
        
        return .init(url: thumbnailURL, height: thumbnail.size.height, width: thumbnail.size.width, mimeType: "image/jpeg", blurhash: blurhash)
    }
        
    private func resizeImage(at url: URL, maxPixelSize: CGFloat, destination: URL, type: UTType) throws(MediaUploadingPreprocessorError) {
        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil) else {
            throw .failedResizingImage
        }
        
        try resizeImage(withSource: imageSource, maxPixelSize: maxPixelSize, destination: destination, type: type)
    }
    
    /// Aspect ratio resizes an image so it fits in the given size. This is useful for resizing images without loading them directly into memory
    /// - Parameters:
    ///   - imageSource: the original image `CGImageSource`
    ///   - maxPixelSize: maximum resulting size for the largest dimension of the image.
    /// - Returns: the resized image
    private func resizeImage(withSource imageSource: CGImageSource, maxPixelSize: CGFloat, destination destinationURL: URL, type: UTType) throws(MediaUploadingPreprocessorError) {
        let options: [NSString: Any] = [
            // The maximum width and height in pixels of a thumbnail.
            kCGImageSourceThumbnailMaxPixelSize: maxPixelSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            // Should include kCGImageSourceCreateThumbnailWithTransform: true in the options dictionary. Otherwise, the image result will appear rotated when an image is taken from camera in the portrait orientation.
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        
        guard let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as NSDictionary),
              let destination = CGImageDestinationCreateWithURL(destinationURL as CFURL, type.identifier as CFString, 1, nil) else {
            throw .failedResizingImage
        }
        let properties = [kCGImageDestinationLossyCompressionQuality: Constants.jpegCompressionQuality]
        
        CGImageDestinationAddImage(destination, scaledImage, properties as NSDictionary)
        CGImageDestinationFinalize(destination)
    }
    
    // MARK: Video Helpers
    
    /// Generates a thumbnail for the video at the given URL
    /// - Parameter url: the video URL
    /// - Returns: the URL for the resulting thumbnail and its sizing info as an `ImageProcessingResult`
    private func generateThumbnailForVideoAt(_ url: URL) async throws(MediaUploadingPreprocessorError) -> ImageProcessingInfo {
        let assetImageGenerator = AVAssetImageGenerator(asset: AVURLAsset(url: url))
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.maximumSize = Constants.maximumThumbnailSize
        
        // Avoid the first frames as on a lot of videos they're black.
        // If the specified seconds are longer than the actual video a frame close to the end of the video will be used, at AVFoundation's discretion
        let location = CMTime(seconds: Constants.videoThumbnailTime, preferredTimescale: 1)
        
        let cgImage: CGImage
        do {
            cgImage = try await assetImageGenerator.image(at: location).image
        } catch {
            throw .failedGeneratingVideoThumbnail(error)
        }
        
        let thumbnail = UIImage(cgImage: cgImage)
        
        guard let data = thumbnail.jpegData(compressionQuality: Constants.jpegCompressionQuality) else {
            throw .failedGeneratingVideoThumbnail(nil)
        }
        
        let blurhash = thumbnail.blurHash(numberOfComponents: (3, 3))
        
        let fileName = "\((url.lastPathComponent as NSString).deletingPathExtension).jpeg"
        let thumbnailURL = url.deletingLastPathComponent().appendingPathComponent(fileName)
        
        do {
            try data.write(to: thumbnailURL)
        } catch {
            throw .failedGeneratingVideoThumbnail(error)
        }
        
        return .init(url: thumbnailURL, height: thumbnail.size.height, width: thumbnail.size.width, mimeType: "image/jpeg", blurhash: blurhash)
    }
    
    /// Converts the given video to an 1080p mp4
    /// - Parameters:
    ///   - url: the original video URL
    ///   - targetFileSize: the maximum resulting file size. 90% of this will be used
    /// - Returns: the URL for the resulting video and its media info as a `VideoProcessingResult`
    private func convertVideoToMP4(_ url: URL, targetFileSize: UInt) async throws(MediaUploadingPreprocessorError) -> VideoProcessingInfo {
        let asset = AVURLAsset(url: url)
        let presetName = appSettings.optimizeMediaUploads ? AVAssetExportPreset1280x720 : AVAssetExportPreset1920x1080

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: presetName) else {
            throw .failedConvertingVideo
        }
        
        // AVAssetExportSession will fail if the output URL already exists
        let uuid = UUID().uuidString
        let originalFilenameWithoutExtension = url.deletingPathExtension().lastPathComponent
        let outputURL = url.deletingLastPathComponent().appendingPathComponent("\(uuid)-\(originalFilenameWithoutExtension).mp4")
        
        try? FileManager.default.removeItem(at: outputURL)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        
        guard exportSession.supportedFileTypes.contains(AVFileType.mp4) else {
            throw .failedConvertingVideo
        }
        
        if targetFileSize > 0 {
            // Reduce the target file size by 10% as fileLengthLimit isn't a hard limit
            exportSession.fileLengthLimit = Int64(Double(targetFileSize) * 0.9)
        }
        
        await exportSession.export()
        
        guard exportSession.status == .completed else {
            throw .failedConvertingVideo
        }
        
        // Delete the original
        try? FileManager.default.removeItem(at: url)
        // Strip the UUID from the new version
        let newOutputURL = url.deletingLastPathComponent().appendingPathComponent("\(originalFilenameWithoutExtension).mp4")
        
        do { try FileManager.default.moveItem(at: outputURL, to: newOutputURL) } catch {
            throw .failedConvertingVideo
        }
        
        let newAsset = AVURLAsset(url: newOutputURL)
        guard let track = try? await newAsset.loadTracks(withMediaType: .video).first,
              let durationInSeconds = try? await newAsset.load(.duration).seconds,
              let adjustedNaturalSize = try? await track.size else {
            throw .failedConvertingVideo
        }
        
        return .init(url: newOutputURL,
                     height: adjustedNaturalSize.height,
                     width: adjustedNaturalSize.width,
                     duration: durationInSeconds,
                     mimeType: "video/mp4")
    }
}

// MARK: - Extensions

private extension CGImageSource {
    var size: CGSize? {
        guard let properties = CGImageSourceCopyPropertiesAtIndex(self, 0, nil) as? [NSString: Any],
              var width = properties[kCGImagePropertyPixelWidth] as? Int,
              var height = properties[kCGImagePropertyPixelHeight] as? Int else {
            return nil
        }
        
        // Make sure the width and height are the correct way around if an orientation is set.
        if let orientationValue = properties[kCGImagePropertyOrientation] as? UInt32,
           let orientation = CGImagePropertyOrientation(rawValue: orientationValue) {
            switch orientation {
            case .up, .down, .upMirrored, .downMirrored:
                break
            case .left, .right, .leftMirrored, .rightMirrored:
                swap(&width, &height)
            }
        }
        
        return CGSize(width: width, height: height)
    }
}

private extension AVAssetTrack {
    var size: CGSize {
        get async throws {
            let naturalSize = try await load(.naturalSize)
            guard mediaType == .video else {
                return naturalSize
            }

            // The naturalSize does not take the preferredTransform into consideration resulting
            // in portrait videos reporting inverted values.
            let transform = try await load(.preferredTransform)

            switch (transform.a, transform.b, transform.c, transform.d) {
            case (0, 1, -1, 0), (0, -1, 1, 0):
                return CGSize(width: naturalSize.height, height: naturalSize.width)
            default:
                return CGSize(width: naturalSize.width, height: naturalSize.height)
            }
        }
    }
}
