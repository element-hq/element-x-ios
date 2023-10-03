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
}

struct AudioConverter {
    func convertToOpusOgg(sourceURL: URL, destinationURL: URL) async throws {
        do {
            try OGGConverter.convertM4aFileToOpusOGG(src: sourceURL, dest: destinationURL)
        } catch {
            MXLog.error("failed to convert to OpusOgg: \(error)")
            throw AudioConverterError.conversionFailed(error)
        }
    }
    
    func convertToMPEG4AAC(sourceURL: URL, destinationURL: URL) async throws {
        do {
            try OGGConverter.convertOpusOGGToM4aFile(src: sourceURL, dest: destinationURL)
        } catch {
            MXLog.error("failed to convert to MPEG4AAC: \(error)")
            throw AudioConverterError.conversionFailed(error)
        }
    }
}
