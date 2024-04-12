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
import MatrixRustSDK

// https://spec.matrix.org/latest/appendices/#identifier-grammar
enum MatrixEntityRegex: String {
    case homeserver
    case userId
    case allUsers
    
    var rawValue: String {
        switch self {
        case .homeserver:
            return "[A-Z0-9]+((\\.|\\-)[A-Z0-9]+){0,}(:[0-9]{2,5})?"
        case .userId:
            return "@[\\x21-\\x39\\x3B-\\x7F]+:" + MatrixEntityRegex.homeserver.rawValue
        case .allUsers:
            return PillConstants.atRoom
        }
    }
    
    // swiftlint:disable force_try
    static var homeserverRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.homeserver.rawValue, options: .caseInsensitive)
    static var userIdentifierRegex = try! NSRegularExpression(pattern: MatrixEntityRegex.userId.rawValue, options: .caseInsensitive)
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
    
    static func containsMatrixAllUsers(_ string: String) -> Bool {
        guard allUsersRegex.firstMatch(in: string) != nil else {
            return false
        }
        
        return true
    }
}
