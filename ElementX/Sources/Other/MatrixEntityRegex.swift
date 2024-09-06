//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

// https://spec.matrix.org/latest/appendices/#identifier-grammar
enum MatrixEntityRegex: String {
    case homeserver
    case userID
    case roomAlias
    case uri
    case allUsers
    
    var rawValue: String {
        switch self {
        case .homeserver:
            return "[A-Z0-9]+((\\.|\\-)[A-Z0-9]+){0,}(:[0-9]{2,5})?"
        case .userID:
            return "@[\\x21-\\x39\\x3B-\\x7F]+:" + MatrixEntityRegex.homeserver.rawValue
        case .roomAlias:
            return "#[A-Z0-9._%#@=+-]+:" + MatrixEntityRegex.homeserver.rawValue
        case .uri:
            return "matrix:(r|u|roomid)\\/[A-Z0-9\\-._~:/?#\\[\\]@!$&'()*+,;=%]*(?:\\?[A-Z0-9\\-._~:/?#\\[\\]@!$&'()*+,;=%]*)?"
        case .allUsers:
            return PillConstants.atRoom
        }
    }
    
    // swiftlint:disable force_try
    static var homeserverRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.homeserver.rawValue, options: .caseInsensitive)
    static var userIdentifierRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.userID.rawValue, options: .caseInsensitive)
    static var roomAliasRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.roomAlias.rawValue, options: .caseInsensitive)
    static var uriRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.uri.rawValue, options: .caseInsensitive)
    static var allUsersRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.allUsers.rawValue)
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
    
    static func isMatrixURI(_ uri: String) -> Bool {
        guard let match = uriRegex.firstMatch(in: uri) else {
            return false
        }
        
        return match.range.length == uri.count
    }
    
    static func containsMatrixAllUsers(_ string: String) -> Bool {
        guard allUsersRegex.firstMatch(in: string) != nil else {
            return false
        }
        
        return true
    }
}
