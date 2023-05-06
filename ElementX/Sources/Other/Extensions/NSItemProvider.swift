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

import Foundation
import UniformTypeIdentifiers

extension NSItemProvider {
    var isSupportedForPasteOrDrop: Bool {
        preferredContentType != nil
    }
    
    var preferredContentType: UTType? {
        let supportedContentTypes = registeredContentTypes
            .filter { isMimeTypeSupported($0.preferredMIMEType) }
        
        // Have .jpeg take priority over .heic
        if supportedContentTypes.contains(.jpeg) {
            return .jpeg
        }
        
        return supportedContentTypes.first
    }
    
    private func isMimeTypeSupported(_ mimeType: String?) -> Bool {
        guard let mimeType else {
            return false
        }
        
        return mimeType.hasPrefix("image/") || mimeType.hasPrefix("video/") || mimeType.hasPrefix("application/")
    }
}
