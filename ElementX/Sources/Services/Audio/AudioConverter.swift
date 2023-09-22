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
import Foundation
import SwiftOGG

enum AudioConverterError: Error {
    case conversionFailed(Error?)
    case getDurationFailed(Error?)
    case cancelled
}

enum AudioConverter {
    static func convertToOpusOgg(sourceURL: URL, destinationURL: URL) async throws {
        do {
            try OGGConverter.convertM4aFileToOpusOGG(src: sourceURL, dest: destinationURL)
        } catch {
            throw AudioConverterError.conversionFailed(error)
        }
    }
    
    static func convertToMPEG4AACIfNeeded(sourceURL: URL, destinationURL: URL) async throws {
        MXLog.debug("[AudioConverter] converting audio file to \(destinationURL.absoluteString)")
        do {
            if sourceURL.hasSupportedAudioExtension {
                try FileManager.default.copyItem(atPath: sourceURL.path, toPath: destinationURL.path)
            } else {
                try OGGConverter.convertOpusOGGToM4aFile(src: sourceURL, dest: destinationURL)
            }
        } catch {
            throw AudioConverterError.conversionFailed(error)
        }
    }
    
    static func mediaDurationAt(_ sourceURL: URL) async throws -> TimeInterval {
        let audioAsset = AVURLAsset(url: sourceURL, options: nil)

        do {
            let duration = try await audioAsset.load(.duration)
            return CMTimeGetSeconds(duration)
        } catch {
            throw AudioConverterError.getDurationFailed(error)
        }
    }
}

extension URL {
    /// Returns true if the URL has a supported audio extension
    var hasSupportedAudioExtension: Bool {
        let supportedExtensions = ["mp3", "mp4", "m4a", "wav", "aac"]
        return supportedExtensions.contains(pathExtension.lowercased())
    }
}

