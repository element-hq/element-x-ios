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
@testable import ElementX
import Foundation

enum FileCacheMockError: Error {
    case someError
}

class FileCacheMock: FileCacheProtocol {
    var fileKey: String?
    var fileExtension: String?
    var fileURLToReturn: URL?
    var storedData: Data?
    var storedFileExtension: String?
    var storedFileKey: String?
    var storeURLToReturn: URL?
    
    func file(forKey key: String, fileExtension: String) -> URL? {
        fileKey = key
        self.fileExtension = fileExtension
        return fileURLToReturn
    }
    
    func store(_ data: Data, with fileExtension: String, forKey key: String) throws -> URL {
        storedData = data
        storedFileExtension = fileExtension
        storedFileKey = key
        if let storeURLToReturn {
            return storeURLToReturn
        } else {
            throw FileCacheMockError.someError
        }
    }
    
    func remove(forKey key: String, fileExtension: String) throws { }
    
    func removeAll() throws { }
}
