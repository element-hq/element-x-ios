//
// Copyright 2023 New Vector Ltd
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

import AVFoundation
import MatrixRustSDK
import UIKit
import UniformTypeIdentifiers

indirect enum MediaUploadingPreprocessorError: Error {
    case failedProcessingMedia(Error)
    
    case failedProcessingImage(MediaUploadingPreprocessorError)
    case failedProcessingVideo(MediaUploadingPreprocessorError)
    case failedProcessingAudio
    case failedProcessingFile
    
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
    let duration: Double
    let mimeType: String
}

struct MediaUploadingPreprocessor {
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
            return await processFile(at: newURL, mimeType: nil)
        }
        
        if type.conforms(to: .image) {
            return await processImage(at: newURL, type: type, mimeType: mimeType)
        } else if type.conforms(to: .movie) || type.conforms(to: .video) {
            return await processVideo(at: newURL)
        } else if type.conforms(to: .audio) {
            return await processAudio(at: newURL, mimeType: mimeType)
        } else {
            return await processFile(at: newURL, mimeType: mimeType)
        }
    }
    
    // MARK: - Private
    
    /// Prepares an image for upload. Strips location data from it and generates a thumbnail
    /// - Parameters:
    ///   - url: The image URL
    ///   - type: its UTType
    ///   - mimeType: the mimeType extracted from the UTType
    /// - Returns: Returns a `MediaInfo.image` containing the URLs for the modified image and its thumbnail plus the corresponding `ImageInfo`
    private func processImage(at url: URL, type: UTType, mimeType: String) async -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        switch await stripLocationFromImage(at: url, type: type, mimeType: mimeType) {
        case .success(let result):
            switch await generateThumbnailForImage(at: url) {
            case .success(let thumbnailResult):
                let imageSize = try? UInt64(FileManager.default.sizeForItem(at: result.url))
                let thumbnailSize = try? UInt64(FileManager.default.sizeForItem(at: thumbnailResult.url))
                
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
            case .failure(let error):
                return .failure(.failedProcessingImage(error))
            }
        case .failure(let error):
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
        switch await convertVideoToMP4(url) {
        case .success(let result):
            switch await generateThumbnailForVideoAt(result.url) {
            case .success(let thumbnailResult):
                let videoSize = try? UInt64(FileManager.default.sizeForItem(at: result.url))
                let thumbnailSize = try? UInt64(FileManager.default.sizeForItem(at: thumbnailResult.url))
                
                let thumbnailInfo = ThumbnailInfo(height: UInt64(thumbnailResult.height),
                                                  width: UInt64(thumbnailResult.width),
                                                  mimetype: thumbnailResult.mimeType,
                                                  size: thumbnailSize)
                
                let videoInfo = VideoInfo(duration: UInt64(result.duration),
                                          height: UInt64(result.height),
                                          width: UInt64(result.width),
                                          mimetype: result.mimeType,
                                          size: videoSize,
                                          thumbnailInfo: thumbnailInfo,
                                          thumbnailSource: nil,
                                          blurhash: thumbnailResult.blurhash)
                
                let mediaInfo = MediaInfo.video(videoURL: result.url, thumbnailURL: thumbnailResult.url, videoInfo: videoInfo)
                
                return .success(mediaInfo)
            case .failure(let error):
                return .failure(.failedProcessingVideo(error))
            }
        case .failure(let error):
            return .failure(.failedProcessingVideo(error))
        }
    }
    
    /// Prepares a file for upload.
    /// - Parameters:
    ///   - url: The audio URL
    ///   - mimeType: the mimeType extracted from the UTType
    /// - Returns: Returns a `MediaInfo.audio` containing the file URL plus the corresponding `AudioInfo`
    private func processAudio(at url: URL, mimeType: String?) async -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        let fileSize = try? UInt64(FileManager.default.sizeForItem(at: url))
        
        let asset = AVURLAsset(url: url)
        guard let durationInSeconds = try? await asset.load(.duration).seconds else {
            return .failure(.failedProcessingAudio)
        }
        
        let audioInfo = AudioInfo(duration: UInt64(durationInSeconds * 1000), size: fileSize, mimetype: mimeType)
        return .success(.audio(audioURL: url, audioInfo: audioInfo))
    }
    
    /// Prepares a file for upload.
    /// - Parameters:
    ///   - url: The file URL
    ///   - type: its UTType
    ///   - mimeType: the mimeType extracted from the UTType
    /// - Returns: Returns a `MediaInfo.file` containing the file URL plus the corresponding `FileInfo`
    private func processFile(at url: URL, mimeType: String?) async -> Result<MediaInfo, MediaUploadingPreprocessorError> {
        let fileSize = try? UInt64(FileManager.default.sizeForItem(at: url))
        
        let fileInfo = FileInfo(mimetype: mimeType, size: fileSize, thumbnailInfo: nil, thumbnailSource: nil)
        return .success(.file(fileURL: url, fileInfo: fileInfo))
    }
    
    // MARK: Images
    
    /// Removes the GPS dictionary from an image's metadata
    /// - Parameters:
    ///   - url: the URL for the original image
    ///   - type: its UTType
    /// - Returns: the URL for the modified image and its size as an `ImageProcessingResult`
    private func stripLocationFromImage(at url: URL, type: UTType, mimeType: String) async -> Result<ImageProcessingInfo, MediaUploadingPreprocessorError> {
        guard let originalData = NSData(contentsOf: url),
              let originalImage = UIImage(data: originalData as Data),
              let imageSource = CGImageSourceCreateWithData(originalData, nil) else {
            return .failure(.failedStrippingLocationData)
        }
        
        guard let originalMetadata = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil),
              (originalMetadata as NSDictionary).value(forKeyPath: "\(kCGImagePropertyGPSDictionary)") != nil else {
            MXLog.info("No GPS metadata found. Returning original image")
            return .success(.init(url: url, height: Double(originalImage.size.height), width: Double(originalImage.size.width), mimeType: mimeType, blurhash: nil))
        }
        
        let count = CGImageSourceGetCount(imageSource)
        let metadataKeysToRemove = [kCGImagePropertyGPSDictionary: kCFNull]
        
        let data = NSMutableData()
        guard let destination = CGImageDestinationCreateWithData(data as CFMutableData, type.identifier as CFString, count, nil) else {
            return .failure(.failedStrippingLocationData)
        }
        CGImageDestinationAddImageFromSource(destination, imageSource, 0, metadataKeysToRemove as NSDictionary)
        CGImageDestinationFinalize(destination)
        
        do {
            try data.write(to: url)
            return .success(.init(url: url, height: Double(originalImage.size.height), width: Double(originalImage.size.width), mimeType: mimeType, blurhash: nil))
        } catch {
            return .failure(.failedStrippingLocationData)
        }
    }
    
    /// Generates a thumbnail for an image
    /// - Parameter url: the original image URL
    /// - Returns: the URL for the resulting thumbnail and its sizing info as an `ImageProcessingResult`
    private func generateThumbnailForImage(at url: URL) async -> Result<ImageProcessingInfo, MediaUploadingPreprocessorError> {
        switch await resizeImage(at: url, targetSize: Constants.maximumThumbnailSize) {
        case .success(let thumbnail):
            guard let data = thumbnail.jpegData(compressionQuality: Constants.thumbnailCompressionQuality) else {
                return .failure(.failedGeneratingImageThumbnail(nil))
            }
            
            let blurhash = thumbnail.blurHash(numberOfComponents: (3, 3))
            
            do {
                let fileName = "thumbnail-\((url.lastPathComponent as NSString).deletingPathExtension).jpeg"
                let thumbnailURL = url.deletingLastPathComponent().appendingPathComponent(fileName)
                try data.write(to: thumbnailURL)
                return .success(.init(url: thumbnailURL, height: thumbnail.size.height, width: thumbnail.size.width, mimeType: "image/jpeg", blurhash: blurhash))
            } catch {
                return .failure(.failedGeneratingImageThumbnail(error))
            }
            
        case .failure(let error):
            return .failure(.failedGeneratingImageThumbnail(error))
        }
    }
        
    private func resizeImage(at url: URL, targetSize: CGSize) async -> Result<UIImage, MediaUploadingPreprocessorError> {
        let imageSource = CGImageSourceCreateWithURL(url as NSURL, nil)
        guard let imageSource else {
            return .failure(.failedResizingImage)
        }
        
        return await resizeImage(withSource: imageSource, targetSize: targetSize)
    }
    
    /// Aspect ratio resizes an image so it fits in the given size. This is useful for resizing images without loading them directly into memory
    /// - Parameters:
    ///   - imageSource: the original image `CGImageSource`
    ///   - targetSize: maximum resulting size
    /// - Returns: the resized image
    private func resizeImage(withSource imageSource: CGImageSource, targetSize: CGSize) async -> Result<UIImage, MediaUploadingPreprocessorError> {
        let maximumSize = min(targetSize.height, targetSize.width)
        
        let options: [NSString: Any] = [
            // The maximum width and height in pixels of a thumbnail.
            kCGImageSourceThumbnailMaxPixelSize: maximumSize,
            kCGImageSourceCreateThumbnailFromImageAlways: true,
            // Should include kCGImageSourceCreateThumbnailWithTransform: true in the options dictionary. Otherwise, the image result will appear rotated when an image is taken from camera in the portrait orientation.
            kCGImageSourceCreateThumbnailWithTransform: true
        ]
        
        guard let scaledImage = CGImageSourceCreateThumbnailAtIndex(imageSource, 0, options as CFDictionary) else {
            return .failure(.failedResizingImage)
        }

        return .success(UIImage(cgImage: scaledImage))
    }
    
    // MARK: Videos
    
    /// Generates a thumbnail for the video at the given URL
    /// - Parameter url: the video URL
    /// - Returns: the URL for the resulting thumbnail and its sizing info as an `ImageProcessingResult`
    private func generateThumbnailForVideoAt(_ url: URL) async -> Result<ImageProcessingInfo, MediaUploadingPreprocessorError> {
        let assetImageGenerator = AVAssetImageGenerator(asset: AVAsset(url: url))
        assetImageGenerator.appliesPreferredTrackTransform = true
        assetImageGenerator.maximumSize = Constants.maximumThumbnailSize
        
        do {
            // Avoid the first frames as on a lot of videos they're black.
            // If the specified seconds are longer than the actual video a frame close to the end of the video will be used, at AVFoundation's discretion
            let location = CMTime(seconds: Constants.videoThumbnailTime, preferredTimescale: 1)
            let cgImage = try await assetImageGenerator.image(at: location).image
            
            let thumbnail = UIImage(cgImage: cgImage)
            
            guard let data = thumbnail.jpegData(compressionQuality: Constants.thumbnailCompressionQuality) else {
                return .failure(.failedGeneratingVideoThumbnail(nil))
            }
            
            let blurhash = thumbnail.blurHash(numberOfComponents: (3, 3))
            
            let fileName = "\((url.lastPathComponent as NSString).deletingPathExtension).jpeg"
            let thumbnailURL = url.deletingLastPathComponent().appendingPathComponent(fileName)
            try data.write(to: thumbnailURL)
            
            return .success(.init(url: thumbnailURL, height: thumbnail.size.height, width: thumbnail.size.width, mimeType: "image/jpeg", blurhash: blurhash))
            
        } catch {
            return .failure(.failedGeneratingVideoThumbnail(error))
        }
    }
    
    /// Converts the given video to an 1080p mp4
    /// - Parameters:
    ///   - url: the original video URL
    ///   - targetFileSize: the maximum resulting file size. 90% of this will be used
    /// - Returns: the URL for the resulting video and its media info as a `VideoProcessingResult`
    private func convertVideoToMP4(_ url: URL, targetFileSize: UInt = 0) async -> Result<VideoProcessingInfo, MediaUploadingPreprocessorError> {
        let asset = AVURLAsset(url: url)

        guard let exportSession = AVAssetExportSession(asset: asset, presetName: AVAssetExportPreset1920x1080) else {
            return .failure(.failedConvertingVideo)
        }
        
        // AVAssetExportSession will fail if the output URL already exists
        let uuid = UUID().uuidString
        let originalFilenameWithoutExtension = url.deletingPathExtension().lastPathComponent
        let outputURL = url.deletingLastPathComponent().appendingPathComponent("\(uuid)-\(originalFilenameWithoutExtension).mp4")
        
        try? FileManager.default.removeItem(at: outputURL)
        
        exportSession.outputURL = outputURL
        exportSession.outputFileType = AVFileType.mp4
        
        guard exportSession.supportedFileTypes.contains(AVFileType.mp4) else {
            return .failure(.failedConvertingVideo)
        }
        
        if targetFileSize > 0 {
            // Reduce the target file size by 10% as fileLengthLimit isn't a hard limit
            exportSession.fileLengthLimit = Int64(Double(targetFileSize) * 0.9)
        }
        
        await exportSession.export()
        
        switch exportSession.status {
        case .completed:
            do {
                // Delete the original
                try? FileManager.default.removeItem(at: url)
                // Strip the UUID from the new version
                let newOutputURL = url.deletingLastPathComponent().appendingPathComponent("\(originalFilenameWithoutExtension).mp4")
                try FileManager.default.moveItem(at: outputURL, to: newOutputURL)
                
                let newAsset = AVURLAsset(url: newOutputURL)
                guard let track = try? await newAsset.loadTracks(withMediaType: .video).first,
                      let durationInSeconds = try? await newAsset.load(.duration).seconds,
                      let naturalSize = try? await track.load(.naturalSize) else {
                    return .failure(.failedConvertingVideo)
                }
                
                return .success(.init(url: newOutputURL,
                                      height: naturalSize.height,
                                      width: naturalSize.width,
                                      duration: durationInSeconds * 1000,
                                      mimeType: "video/mp4"))
            } catch {
                return .failure(.failedConvertingVideo)
            }
        default:
            return .failure(.failedConvertingVideo)
        }
    }
}
