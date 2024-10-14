//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AVFoundation
import MatrixRustSDK
import UIKit
import UniformTypeIdentifiers

indirect enum MediaUploadingPreprocessorError: Error {
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
        static let thumbnailCompressionQuality = 0.8
        static let videoThumbnailTime = 5.0 // seconds
    }
    
    /// Processes media at a given URL. It will generate thumbnails for images and videos, convert videos to 1080p mp4, strip GPS locations
    /// from images and retrieve associated media information
    /// - Parameter url: the file URL
    /// - Returns: a specific type of `MediaInfo` depending on the file type and its associated details
    func processMedia(at url: URL) async -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        // Start by copying the file to a unique temporary location in order to avoid conflicts if processing it multiple times
        // All the other operations will be made relative to it
        let uniqueFolder = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        let newURL = uniqueFolder.appendingPathComponent(url.lastPathComponent)
        do {
            try FileManager.default.createDirectory(at: uniqueFolder, withIntermediateDirectories: true)
            try FileManager.default.copyItem(at: url, to: newURL)
        } catch {
            return .failure(.failedProcessingMedia(error))
        }
        
        // Process unknown types as plain files
        guard let type = UTType(filenameExtension: newURL.pathExtension),
              let mimeType = type.preferredMIMEType else {
            return processFile(at: newURL, mimeType: "application/octet-stream")
        }
        
        if type.conforms(to: .image) {
            return processImage(at: newURL, type: type, mimeType: mimeType)
        } else if type.conforms(to: .movie) || type.conforms(to: .video) {
            return await processVideo(at: newURL)
        } else if type.conforms(to: .audio) {
            return await processAudio(at: newURL, mimeType: mimeType)
        } else {
            return processFile(at: newURL, mimeType: mimeType)
        }
    }
    
    // MARK: - Private
    
    /// Prepares an image for upload. Strips location data from it and generates a thumbnail
    /// - Parameters:
    ///   - url: The image URL
    ///   - type: its UTType
    ///   - mimeType: the mimeType extracted from the UTType
    /// - Returns: Returns a `MediaInfo.image` containing the URLs for the modified image and its thumbnail plus the corresponding `ImageInfo`
    private func processImage(at url: URL, type: UTType, mimeType: String) -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        do {
            let result = try stripLocationFromImage(at: url, type: type, mimeType: mimeType)
            let thumbnailResult = try generateThumbnailForImage(at: url)
            
            let imageSize = (try? UInt64(FileManager.default.sizeForItem(at: result.url))) ?? 0
            let thumbnailSize = (try? UInt64(FileManager.default.sizeForItem(at: thumbnailResult.url))) ?? 0
            
            let thumbnailInfo = ThumbnailInfo(height: UInt64(thumbnailResult.height),
                                              width: UInt64(thumbnailResult.width),
                                              mimetype: thumbnailResult.mimeType,
                                              size: thumbnailSize)
            
            let imageInfo = ImageInfo(height: UInt64(result.height),
                                      width: UInt64(result.width),
                                      mimetype: result.mimeType,
                                      size: imageSize,
                                      thumbnailInfo: thumbnailInfo,
                                      thumbnailSource: nil,
                                      blurhash: thumbnailResult.blurhash)
            
            let mediaInfo = MediaInfo.image(imageURL: result.url, thumbnailURL: thumbnailResult.url, imageInfo: imageInfo)
            
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
    private func processVideo(at url: URL) async -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        do {
            let result = try await convertVideoToMP4(url)
            let thumbnailResult = try await generateThumbnailForVideoAt(result.url)
            
            let videoSize = (try? UInt64(FileManager.default.sizeForItem(at: result.url))) ?? 0
            let thumbnailSize = (try? UInt64(FileManager.default.sizeForItem(at: thumbnailResult.url))) ?? 0
            
            let thumbnailInfo = ThumbnailInfo(height: UInt64(thumbnailResult.height),
                                              width: UInt64(thumbnailResult.width),
                                              mimetype: thumbnailResult.mimeType,
                                              size: thumbnailSize)
            
            let videoInfo = VideoInfo(duration: result.duration,
                                      height: UInt64(result.height),
                                      width: UInt64(result.width),
                                      mimetype: result.mimeType,
                                      size: videoSize,
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
    private func processAudio(at url: URL, mimeType: String?) async -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        let fileSize = (try? UInt64(FileManager.default.sizeForItem(at: url))) ?? 0
        
        let asset = AVURLAsset(url: url)
        guard let durationInSeconds = try? await asset.load(.duration).seconds else {
            return .failure(.failedProcessingAudio)
        }
        
        let audioInfo = AudioInfo(duration: durationInSeconds, size: fileSize, mimetype: mimeType)
        return .success(.audio(audioURL: url, audioInfo: audioInfo))
    }
    
    /// Prepares a file for upload.
    /// - Parameters:
    ///   - url: The file URL
    ///   - type: its UTType
    ///   - mimeType: the mimeType extracted from the UTType
    /// - Returns: Returns a `MediaInfo.file` containing the file URL plus the corresponding `FileInfo`
    private func processFile(at url: URL, mimeType: String?) -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        let fileSize = (try? UInt64(FileManager.default.sizeForItem(at: url))) ?? 0
        
        let fileInfo = FileInfo(mimetype: mimeType, size: fileSize, thumbnailInfo: nil, thumbnailSource: nil)
        return .success(.file(fileURL: url, fileInfo: fileInfo))
    }
    
    // MARK: Image Helpers
    
    /// Removes the GPS dictionary from an image's metadata
    /// - Parameters:
    ///   - url: the URL for the original image
    ///   - type: its UTType
    /// - Returns: the URL for the modified image and its size as an `ImageProcessingResult`
    private func stripLocationFromImage(at url: URL, type: UTType, mimeType: String) throws(MediaUploadingPreprocessorError) -> ImageProcessingInfo {
        guard let originalData = NSData(contentsOf: url),
              let originalImage = UIImage(data: originalData as Data),
              let imageSource = CGImageSourceCreateWithData(originalData, nil) else {
            throw .failedStrippingLocationData
        }
        
        guard let originalMetadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil),
              (originalMetadata as NSDictionary).value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") != nil else {
            MXLog.info("No GPS metadata found. Returning original image")
            return .init(url: url, height: Double(originalImage.size.height), width: Double(originalImage.size.width), mimeType: mimeType, blurhash: nil)
        }
        
        let count = CGImageSourceGetCount(imageSource)
        let metadataKeysToRemove = [kCGImagePropertyGPSDictionary: kCFNull]
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, type.identifier as CFString, count, nil) else {
            throw .failedStrippingLocationData
        }
        CGImageDestinationAddImageFromSource(destination, imageSource, 0, metadataKeysToRemove as NSDictionary)
        CGImageDestinationFinalize(destination)
        
        do {
            try data.write(to: url)
            return .init(url: url, height: Double(originalImage.size.height), width: Double(originalImage.size.width), mimeType: mimeType, blurhash: nil)
        } catch {
            throw .failedStrippingLocationData
        }
    }
    
    /// Generates a thumbnail for an image
    /// - Parameter url: the original image URL
    /// - Returns: the URL for the resulting thumbnail and its sizing info as an `ImageProcessingResult`
    private func generateThumbnailForImage(at url: URL) throws(MediaUploadingPreprocessorError) -> ImageProcessingInfo {
        let thumbnail: UIImage
        do {
            thumbnail = try resizeImage(at: url, targetSize: Constants.maximumThumbnailSize)
        } catch {
            throw .failedGeneratingImageThumbnail(error)
        }
        
        guard let data = thumbnail.jpegData(compressionQuality: Constants.thumbnailCompressionQuality) else {
            throw .failedGeneratingImageThumbnail(nil)
        }
        
        let blurhash = thumbnail.blurHash(numberOfComponents: (3, 3))
        
        do {
            let fileName = "thumbnail-\((url.lastPathComponent as NSString).deletingPathExtension).jpeg"
            let thumbnailURL = url.deletingLastPathComponent().appendingPathComponent(fileName)
            try data.write(to: thumbnailURL)
            return .init(url: thumbnailURL, height: thumbnail.size.height, width: thumbnail.size.width, mimeType: "image/jpeg", blurhash: blurhash)
        } catch {
            throw .failedGeneratingImageThumbnail(error)
        }
    }
        
    private func resizeImage(at url: URL, targetSize: CGSize) throws(MediaUploadingPreprocessorError) -> UIImage {
        guard let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil) else {
            throw .failedResizingImage
        }
        
        return try resizeImage(withSource: imageSource, targetSize: targetSize)
    }
    
    /// Aspect ratio resizes an image so it fits in the given size. This is useful for resizing images without loading them directly into memory
    /// - Parameters:
    ///   - imageSource: the original image `CGImageSource`
    ///   - targetSize: maximum resulting size
    /// - Returns: the resized image
    private func resizeImage(withSource imageSource: CGImageSource, targetSize: CGSize) throws(MediaUploadingPreprocessorError) -> UIImage {
        let maximumSize = max(targetSize.height, targetSize.width)
        
        let options: [NSString: Any] = [
            // The maximum width and height in pixels of a thumbnail.
            kCGImageSourceThumbnailMaxPixelSize: maximumSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            // Should include kCGImageSourceCreateThumbnailWithTransform: true in the options dictionary. Otherwise, the image result will appear rotated when an image is taken from camera in the portrait orientation.
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        
        guard let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            throw .failedResizingImage
        }

        return UIImage(cgImage: scaledImage)
    }
    
    // MARK: Video Helpers
    
    /// Generates a thumbnail for the video at the given URL
    /// - Parameter url: the video URL
    /// - Returns: the URL for the resulting thumbnail and its sizing info as an `ImageProcessingResult`
    private func generateThumbnailForVideoAt(_ url: URL) async throws(MediaUploadingPreprocessorError) -> ImageProcessingInfo {
        let assetImageGenerator = AVAssetImageGenerator(asset: AVAsset(url: url))
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
        
        guard let data = thumbnail.jpegData(compressionQuality: Constants.thumbnailCompressionQuality) else {
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
    private func convertVideoToMP4(_ url: URL, targetFileSize: UInt = 0) async throws(MediaUploadingPreprocessorError) -> VideoProcessingInfo {
        let asset = AVURLAsset(url: url)
        let presetName = appSettings.optimizeMediaUploads ? AVAssetExportPreset640x480 : AVAssetExportPreset1920x1080

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
