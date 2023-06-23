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

enum PermalinkType: Equatable {
    case userIdentifier(String)
    case roomIdentifier(String)
    case roomAlias(String)
    case event(roomIdentifier: String, eventIdentifier: String)
}

enum PermalinkBuilder {
    private static var uriComponentCharacterSet: CharacterSet = {
        var charset = CharacterSet.alphanumerics
        charset.insert(charactersIn: "-_.!~*'()")
        return charset
    }()
    
    static func detectPermalink(in url: URL, baseURL: URL) -> PermalinkType? {
        guard url.absoluteString.hasPrefix(baseURL.absoluteString) else {
            return nil
        }
        
        guard let urlComponents = URLComponents(url: url, resolvingAgainstBaseURL: true) else {
            return nil
        }
        
        guard var fragment = urlComponents.fragment else {
            return nil
        }
        
        if fragment.hasPrefix("/") {
            fragment = String(fragment.dropFirst(1))
        }
        
        if let userIdentifierRange = MatrixEntityRegex.userIdentifierRegex.firstMatch(in: fragment)?.range {
            return .userIdentifier((fragment as NSString).substring(with: userIdentifierRange))
        }
        
        if let roomAliasRange = MatrixEntityRegex.roomAliasRegex.firstMatch(in: fragment)?.range {
            return .roomAlias((fragment as NSString).substring(with: roomAliasRange))
        }
        
        if let roomIdentifierRange = MatrixEntityRegex.roomIdentifierRegex.firstMatch(in: fragment)?.range {
            let roomIdentifier = (fragment as NSString).substring(with: roomIdentifierRange)
            
            if let eventIdentifierRange = MatrixEntityRegex.eventIdentifierRegex.firstMatch(in: fragment)?.range {
                let eventIdentifier = (fragment as NSString).substring(with: eventIdentifierRange)
                return .event(roomIdentifier: roomIdentifier, eventIdentifier: eventIdentifier)
            }
            
            return .roomIdentifier(roomIdentifier)
        }

        return nil
    }
    
    static func permalinkTo(userIdentifier: String, baseURL: URL) throws -> URL {
        guard MatrixEntityRegex.isMatrixUserIdentifier(userIdentifier) else {
            throw PermalinkBuilderError.invalidUserIdentifier
        }
        
        let urlString = "\(baseURL)/#/\(userIdentifier)"
        
        guard let url = URL(string: urlString) else {
            throw PermalinkBuilderError.failedConstructingURL
        }
        
        return url
    }
    
    static func permalinkTo(roomIdentifier: String, baseURL: URL) throws -> URL {
        guard MatrixEntityRegex.isMatrixRoomIdentifier(roomIdentifier) else {
            throw PermalinkBuilderError.invalidRoomIdentifier
        }
        
        return try permalinkTo(roomIdentifierOrAlias: roomIdentifier, baseURL: baseURL)
    }
    
    static func permalinkTo(roomAlias: String, baseURL: URL) throws -> URL {
        guard MatrixEntityRegex.isMatrixRoomAlias(roomAlias) else {
            throw PermalinkBuilderError.invalidRoomAlias
        }
        
        return try permalinkTo(roomIdentifierOrAlias: roomAlias, baseURL: baseURL)
    }
    
    static func permalinkTo(eventIdentifier: String, roomIdentifier: String, baseURL: URL) throws -> URL {
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
        
        let urlString = "\(baseURL)/#/\(roomId)/\(eventId)"
        
        guard let url = URL(string: urlString) else {
            throw PermalinkBuilderError.failedConstructingURL
        }
        
        return url
    }
    
    // MARK: - Private
    
    private static func permalinkTo(roomIdentifierOrAlias: String, baseURL: URL) throws -> URL {
        guard let identifier = roomIdentifierOrAlias.addingPercentEncoding(withAllowedCharacters: uriComponentCharacterSet) else {
            throw PermalinkBuilderError.failedAddingPercentEncoding
        }
        
        let urlString = "\(baseURL)/#/\(identifier)"
        
        guard let url = URL(string: urlString) else {
            throw PermalinkBuilderError.failedConstructingURL
        }
        
        return url
    }
}
