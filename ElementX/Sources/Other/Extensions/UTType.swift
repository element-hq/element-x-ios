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
