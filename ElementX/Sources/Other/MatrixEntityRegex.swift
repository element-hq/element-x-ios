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

// https://spec.matrix.org/latest/appendices/#identifier-grammar
enum MatrixEntityRegex: String {
    case homeserver
    case userId
    case roomAlias
    case roomId
    case eventId
    
    var rawValue: String {
        switch self {
        case .homeserver:
            return "[A-Z0-9]+((\\.|\\-)[A-Z0-9]+){0,}(:[0-9]{2,5})?"
        case .userId:
            return "@[\\x21-\\x39\\x3B-\\x7F]+:" + MatrixEntityRegex.homeserver.rawValue
        case .roomAlias:
            return "#[A-Z0-9._%#@=+-]+:" + MatrixEntityRegex.homeserver.rawValue
        case .roomId:
            return "![A-Z0-9]+:" + MatrixEntityRegex.homeserver.rawValue
        case .eventId:
            return "\\$[a-z0-9_\\-\\/]+(:[a-z0-9]+\\.[a-z0-9]+)?"
        }
    }
    
    // swiftlint:disable force_try
    static var homeserverRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.homeserver.rawValue, options: .caseInsensitive)
    static var userIdentifierRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.userId.rawValue, options: .caseInsensitive)
    static var roomAliasRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.roomAlias.rawValue, options: .caseInsensitive)
    static var roomIdentifierRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.roomId.rawValue, options: .caseInsensitive)
    static var eventIdentifierRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.eventId.rawValue, options: .caseInsensitive)
    static var linkRegex = try! NSDataDetector(types: NSTextCheckingResult.CheckingType.link.rawValue)
    // swiftlint:enable force_try
    
    static func isMatrixHomeserver(_ homeserver: String) -> Bool {
        guard let match = homeserverRegex.firstMatch(in: homeserver) else {
            return false
        }
        
        return match.range.length == homeserver.count
    }
    
    static func isMatrixUserIdentifier(_ identifier: String) -> Bool {
        guard let match = userIdentifierRegex.firstMatch(in: identifier) else {
            return false
        }
        
        return match.range.length == identifier.count
    }
    
    static func isMatrixRoomAlias(_ alias: String) -> Bool {
        guard let match = roomAliasRegex.firstMatch(in: alias) else {
            return false
        }
        
        return match.range.length == alias.count
    }
    
    static func isMatrixRoomIdentifier(_ identifier: String) -> Bool {
        guard let match = roomIdentifierRegex.firstMatch(in: identifier) else {
            return false
        }
        
        return match.range.length == identifier.count
    }
        
    static func isMatrixEventIdentifier(_ identifier: String) -> Bool {
        guard let match = eventIdentifierRegex.firstMatch(in: identifier) else {
            return false
        }
        
        return match.range.length == identifier.count
    }
}
