//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import AVFoundation
import Foundation
import SwiftOGG

enum AudioConverterError: Error {
    case conversionFailed(Error?)
}

enum AudioConverterPreferredFileExtension: String {
    case mpeg4aac = "m4a"
    case ogg
}

struct AudioConverter: AudioConverterProtocol {
    func convertToOpusOgg(sourceURL: URL, destinationURL: URL) throws {
        do {
            try OGGConverter.convertM4aFileToOpusOGG(src: sourceURL, dest: destinationURL)
        } catch {
            MXLog.error("failed to convert to OpusOgg: \(error)")
            throw AudioConverterError.conversionFailed(error)
        }
    }
    
    func convertToMPEG4AAC(sourceURL: URL, destinationURL: URL) throws {
        do {
            try OGGConverter.convertOpusOGGToM4aFile(src: sourceURL, dest: destinationURL)
        } catch {
            MXLog.error("failed to convert to MPEG4AAC: \(error)")
            throw AudioConverterError.conversionFailed(error)
        }
    }
}
