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

enum PermalinkBuilderError: Error {
    case invalidUserIdentifier
    case invalidRoomIdentifier
    case invalidRoomAlias
    case invalidEventIdentifier
    case failedConstructingURL
    case failedAddingPercentEncoding
}

enum PermalinkBuilder {
    static var uriComponentCharacterSet: CharacterSet = {
        var charset = CharacterSet.alphanumerics
        charset.insert(charactersIn: "-_.!~*'()")
        return charset
    }()
    
    static func permalinkTo(userIdentifier: String) throws -> URL {
        guard MatrixEntityRegex.isMatrixUserIdentifier(userIdentifier) else {
            throw PermalinkBuilderError.invalidUserIdentifier
        }
        
        let urlString = "\(BuildSettings.permalinkBaseURL)/#/\(userIdentifier)"
        
        guard let url = URL(string: urlString) else {
            throw PermalinkBuilderError.failedConstructingURL
        }
        
        return url
    }
    
    static func permalinkTo(roomIdentifier: String) throws -> URL {
        guard MatrixEntityRegex.isMatrixRoomIdentifier(roomIdentifier) else {
            throw PermalinkBuilderError.invalidRoomIdentifier
        }
        
        return try permalinkTo(roomIdentifierOrAlias: roomIdentifier)
    }
    
    static func permalinkTo(roomAlias: String) throws -> URL {
        guard MatrixEntityRegex.isMatrixRoomAlias(roomAlias) else {
            throw PermalinkBuilderError.invalidRoomAlias
        }
        
        return try permalinkTo(roomIdentifierOrAlias: roomAlias)
    }
    
    static func permalinkTo(eventIdentifier: String, roomIdentifier: String) throws -> URL {
        guard MatrixEntityRegex.isMatrixEventIdentifier(eventIdentifier) else {
            throw PermalinkBuilderError.invalidEventIdentifier
        }
        guard MatrixEntityRegex.isMatrixRoomIdentifier(roomIdentifier) else {
            throw PermalinkBuilderError.invalidRoomIdentifier
        }
        
        guard let roomId = roomIdentifier.addingPercentEncoding(withAllowedCharacters: uriComponentCharacterSet),
              let eventId = eventIdentifier.addingPercentEncoding(withAllowedCharacters: uriComponentCharacterSet) else {
            throw PermalinkBuilderError.failedAddingPercentEncoding
        }
        
        let urlString = "\(BuildSettings.permalinkBaseURL)/#/\(roomId)/\(eventId)"
        
        guard let url = URL(string: urlString) else {
            throw PermalinkBuilderError.failedConstructingURL
        }
        
        return url
    }
    
    // MARK: - Private
    
    private static func permalinkTo(roomIdentifierOrAlias: String) throws -> URL {
        guard let identifier = roomIdentifierOrAlias.addingPercentEncoding(withAllowedCharacters: uriComponentCharacterSet) else {
            throw PermalinkBuilderError.failedAddingPercentEncoding
        }
        
        let urlString = "\(BuildSettings.permalinkBaseURL)/#/\(identifier)"
        
        guard let url = URL(string: urlString) else {
            throw PermalinkBuilderError.failedConstructingURL
        }
        
        return url
    }
}
