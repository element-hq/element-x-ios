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

import XCTest

@testable import ElementX

final class MediaUploadingPreprocessorTests: XCTestCase {
    let mediaUploadingPreprocessor = MediaUploadingPreprocessor()
    
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
        XCTAssertEqual(audioInfo.duration, 27252)
        XCTAssertEqual(audioInfo.size, 764_176)
    }
    
    func testVideoProcessing() async {
        guard let url = Bundle(for: Self.self).url(forResource: "test_video.mov", withExtension: nil) else {
            XCTFail("Failed retrieving test asset")
            return
        }
        
        guard case let .success(result) = await mediaUploadingPreprocessor.processMedia(at: url),
              case let .video(videoURL, thumbnailURL, videoInfo) = result else {
            XCTFail("Failed processing asset")
            return
        }
        
        // Check that the file name is preserved
        XCTAssertEqual(videoURL.lastPathComponent, "test_video.mp4")
        
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
        XCTAssertEqual(videoInfo.size, 1_431_959)
        XCTAssertEqual(videoInfo.width, 1280)
        XCTAssertEqual(videoInfo.height, 720)
        XCTAssertEqual(videoInfo.duration, 30483)
        
        XCTAssertNotNil(videoInfo.thumbnailInfo)
        XCTAssertEqual(videoInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(videoInfo.thumbnailInfo?.size, 33949)
        XCTAssertEqual(videoInfo.thumbnailInfo?.width, 800)
        XCTAssertEqual(videoInfo.thumbnailInfo?.height, 450)
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
        XCTAssertEqual(imageInfo.size, 3_305_795)
        XCTAssertEqual(imageInfo.width, 6103)
        XCTAssertEqual(imageInfo.height, 2621)
        
        XCTAssertNotNil(imageInfo.thumbnailInfo)
        XCTAssertEqual(imageInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(imageInfo.thumbnailInfo?.size, 52159)
        XCTAssertEqual(imageInfo.thumbnailInfo?.width, 600)
        XCTAssertEqual(imageInfo.thumbnailInfo?.height, 257)
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
        XCTAssertEqual(imageInfo.blurhash, "KdE:ess+RP^-n*RP%hWAV@")
        XCTAssertEqual(imageInfo.size, 4_414_666)
        XCTAssertEqual(imageInfo.width, 3024)
        XCTAssertEqual(imageInfo.height, 4032)
        
        XCTAssertNotNil(imageInfo.thumbnailInfo)
        XCTAssertEqual(imageInfo.thumbnailInfo?.mimetype, "image/jpeg")
        XCTAssertEqual(imageInfo.thumbnailInfo?.size, 156_948)
        XCTAssertEqual(imageInfo.thumbnailInfo?.width, 450)
        XCTAssertEqual(imageInfo.thumbnailInfo?.height, 600)
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
        guard let imageSource = CGImageSourceCreateWithData(originalImageData as NSData, nil) else {
            XCTFail("Invalid test asset")
            return
        }
        
        guard let originalMetadata: NSDictionary = CGImageSourceCopyPropertiesAtIndex(imageSource, 0, nil) else {
            XCTFail("Test asset is expected to contain metadata")
            return
        }
        
        XCTAssertNotNil(originalMetadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)"))
        
        guard let convertedImageSource = CGImageSourceCreateWithData(convertedImageData as NSData, nil) else {
            XCTFail("Invalid converted asset")
            return
        }
        
        guard let convertedMetadata: NSDictionary = CGImageSourceCopyPropertiesAtIndex(convertedImageSource, 0, nil) else {
            XCTFail("Test asset is expected to contain metadata")
            return
        }
        
        XCTAssertNil(convertedMetadata.value(forKeyPath: "\(kCGImagePropertyGPSDictionary)"))
        
        // Check that the thumbnail is generated correctly
        guard let thumbnailData = try? Data(contentsOf: thumbnailURL),
              let thumbnail = UIImage(data: thumbnailData) else {
            XCTFail("Invalid thumbnail")
            return
        }
        
        XCTAssert(thumbnail.size.width <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.width)
        XCTAssert(thumbnail.size.height <= MediaUploadingPreprocessor.Constants.maximumThumbnailSize.height)
    }
}
