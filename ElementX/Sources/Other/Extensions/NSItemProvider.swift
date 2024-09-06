//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        
        // Prevents media upload triggering for text copied from Notes.app #1247
        if mimeType == "application/x-webarchive" {
            return false
        }
        
        return mimeType.hasPrefix("image/") || mimeType.hasPrefix("video/") || mimeType.hasPrefix("application/")
    }
}
