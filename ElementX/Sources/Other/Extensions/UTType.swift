//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import UniformTypeIdentifiers

extension UTType {
    /// Creates a type based on an optional mime type, falling back to a filename when this type is missing or unknown.
    init?(mimeType: String?, fallbackFilename: String) {
        guard let mimeType, let type = UTType(mimeType: mimeType) else {
            self.init(filename: fallbackFilename)
            return
        }
        self = type
    }
    
    /// Creates a type based on a filename.
    private init?(filename: String) {
        let components = filename.split(separator: ".")
        guard components.count > 1, let filenameExtension = components.last else { return nil }
        self.init(filenameExtension: String(filenameExtension))
    }
}
