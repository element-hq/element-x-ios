//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum PhishingDetector {
    static func isPhishingAttempt(displayString: String, internalURL: URL) -> Bool {
        // Some phishing attempts can be hidden by using the unicode character "﹒" instead of "."
        let disambiguatedDisplayString = displayString.replacingOccurrences(of: "﹒", with: ".")
        let linkMatch = MatrixEntityRegex.linkRegex.firstMatch(in: disambiguatedDisplayString)
        let linkMatchLength = linkMatch?.range.length ?? 0

        // We check if we the link string contains a matrix user ID.
        if let match = MatrixEntityRegex.userIdentifierRegex.firstMatch(in: disambiguatedDisplayString),
           // If there is a bigger permalink including it we leave it handled by the link branch
           linkMatchLength <= match.range.length,
           let matchRange = Range(match.range, in: disambiguatedDisplayString) {
            let identifier = String(disambiguatedDisplayString[matchRange])
            
            // We also make sure that the link string is just the user ID
            // We also trim any invalid character that might hide the phishing attempt
            // Like by using whitespaces emojis or other invalid symbols e.g click here [👉️ @alice:matrix.org](https://matrix.org)
            let trimmedDisplayString = disambiguatedDisplayString.lowercased().trimmingCharacters(in: .matrixUserIDAllowedCharacters.inverted)
            if identifier == trimmedDisplayString,
               isMatrixUserIDPhishingAttempt(internalURL: internalURL, identifier: identifier) {
                return true
            }
            // We check if we the link string contains a room alias.
        } else if let match = MatrixEntityRegex.roomAliasRegex.firstMatch(in: disambiguatedDisplayString),
                  // If there is a bigger permalink including it we leave it handled by the link branch
                  linkMatchLength <= match.range.length,
                  let matchRange = Range(match.range, in: disambiguatedDisplayString) {
            let alias = String(disambiguatedDisplayString[matchRange])
            
            // We also make sure that the link string is just the user ID
            // We also trim any invalid character that might hide the phishing attempt
            // Like by using whitespaces emojis or other invalid symbols e.g click here [👉️ #room:matrix.org](https://matrix.org)
            let trimmedDisplayString = disambiguatedDisplayString.lowercased().trimmingCharacters(in: .roomAliasAllowedCharacters.inverted)
            if alias == trimmedDisplayString,
               isRoomAliasPhishingAttempt(internalURL: internalURL, alias: alias) {
                return true
            }
            // Else we check if the link string is itself what is considered a tappable link for the OS
        } else if linkMatch != nil {
            // Then we compare the external URL with the internal one
            // To avoid false positives like [Matrix.org](https://matrix.org) we sanitize and lowercase
            // And trim invalid characters that might hide phishing attemps
            // Like emoji whitespaces and other invalid symbols e.g click here [👉️ https://element.io](https://matrix.org)
            let trimmedDisplayString = disambiguatedDisplayString.asSanitizedLink.lowercased().trimmingCharacters(in: .urlAllowedCharacters.inverted)
            if trimmedDisplayString != internalURL.absoluteString.asSanitizedLink.lowercased().removingPercentEncoding {
                return true
            }
        }
        
        return false
    }
    
    private static func isMatrixUserIDPhishingAttempt(internalURL: URL, identifier: String) -> Bool {
        // if is not a matrix entity then is a phishing attempt
        guard let internalMatrixEntity = parseMatrixEntityFrom(uri: internalURL.absoluteString) else {
            return true
        }
        
        // If it is we check if is a user
        switch internalMatrixEntity.id {
        case .user(let id):
            // If it is, and it does not match the external one, it's a phishing attempt
            return id != identifier
        default:
            break
        }
        return true
    }
    
    private static func isRoomAliasPhishingAttempt(internalURL: URL, alias: String) -> Bool {
        // if is not a matrix entity then is a phishing attempt
        guard let internalMatrixEntity = parseMatrixEntityFrom(uri: internalURL.absoluteString) else {
            return true
        }
        
        // If it is we check if is a user
        switch internalMatrixEntity.id {
        case .roomAlias(let internalAlias):
            // If it is, and it does not match the external one, it's a phishing attempt
            return alias != internalAlias
        default:
            break
        }
        return true
    }
}
