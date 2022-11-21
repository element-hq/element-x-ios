//
// Copyright 2022 New Vector Ltd
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

extension FileManager {
    func directoryExists(at url: URL) -> Bool {
        var isDirectory: ObjCBool = false
        guard fileExists(atPath: url.path(), isDirectory: &isDirectory) else {
            return false
        }
        return isDirectory.boolValue
    }

    func createDirectoryIfNeeded(at url: URL, withIntermediateDirectories: Bool = true) throws {
        guard !directoryExists(at: url) else {
            return
        }
        try createDirectory(at: url, withIntermediateDirectories: withIntermediateDirectories)
    }
}
