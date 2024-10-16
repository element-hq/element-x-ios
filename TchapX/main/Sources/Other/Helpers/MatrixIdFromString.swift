/*
 * MIT License
 *
 * Copyright (c) 2024. DINUM
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
 * MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
 * OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE
 * OR OTHER DEALINGS IN THE SOFTWARE.
 */

//
//  MatrixIdFromString.swift
//  Tchap X
//
//  Created by Nicolas Buquet on 03/10/2024.
//  Copyright © 2024 Tchap. All rights reserved.
//

import Foundation

struct MatrixIdFromString {
    private static let MATRIXID_PARTS_SEPARATOR: Character = ":"
    private static let HOMESERVER_SPECIAL_SUFFIX_TCHAP = "tchap.gouv.fr"
    private static let HOMESERVER_PARTS_SEPARATOR: Character = "."
    private static let HOMESERVER_EXTERN_PREFIX_LIST = ["e.", "agent.externe."]

    private var mxIdString: String

    init(_ mxIdString: String) {
        self.mxIdString = mxIdString
    }
    
    /// Get the homeserver name of a matrix identifier.
    ///
    /// - Returns: the homeserver name, if any, `nil` otherwise.
    ///
    /// The identifier type may be any matrix identifier type: user id, room id, ...
    ///
    /// For example in case of "@jean-philippe.martin-modernisation.fr:matrix.test.org", this will return "matrix.test.org".
    ///
    /// In case of "!AAAAAAA:matrix.test.org", this will return "matrix.test.org".
    
    var homeServerName: Substring {
        guard let splitIndex = mxIdString.firstIndex(of: Self.MATRIXID_PARTS_SEPARATOR) else {
            return ""
        }
        return mxIdString[mxIdString.index(after: splitIndex)...]
    }
    
    /// Get the Tchap display name of the homeserver mentioned in a matrix identifier.
    ///
    /// - Returns: the Tchap display name of the homeserver.
    ///
    /// The identifier type may be any matrix identifier type: user id, room id, ...
    ///
    /// The returned name is capitalized.
    ///
    /// The Tchap HS display name is the component mentioned before the suffix "tchap.gouv.fr"
    ///
    /// For example in case of "@jean-philippe.martin-modernisation.fr:name1.tchap.gouv.fr", this will return "Name1".
    /// in case of "@jean-philippe.martin-modernisation.fr:agent.name2.tchap.gouv.fr", this will return "Name2".
    
    var homeServerDisplayName: Substring {
        var homeserverName = homeServerName
        if homeserverName.hasSuffix(Self.HOMESERVER_SPECIAL_SUFFIX_TCHAP) {
            let homeserverNameComponents = homeserverName.split(separator: Self.HOMESERVER_PARTS_SEPARATOR)
            if homeserverNameComponents.count >= 4 {
                homeserverName = homeserverNameComponents[homeserverNameComponents.count - 4]
            }
        }
        return homeserverName.prefix(1).localizedCapitalized + homeserverName.localizedLowercase.dropFirst()
    }
    
    /// Tells whether a homeserver name corresponds to an external server or not.
    ///
    /// - Returns: true if external.
    
    var isExternalTchapServer: Bool {
        let homeServer = homeServerName
        return homeServer.isEmpty || Self.HOMESERVER_EXTERN_PREFIX_LIST.contains { homeServer.hasPrefix($0) }
    }
    
    /// Tells whether the provided tchap identifier corresponds to an extern user.
    ///
    /// Note: invalid tchap identifier will be considered as external.
    ///
    /// - Returns: true if external.
    
    var isExternalTchapUser: Bool {
        isExternalTchapServer
    }

    /// Build a display name from the tchap user identifier.
    ///
    /// - Returns: displayName without domain, or null if the user identifier is not valid.
    ///
    /// We don't extract the domain for the moment in order to not display unexpected information.
    ///
    /// For example in case of "@jean-philippe.martin-modernisation.fr:matrix.org", this will return "Jean-Philippe Martin".
    ///
    /// Note: in case of an external user identifier, we return the local part of the id which corresponds to their email.

    var userDisplayName: UserDisplayName? {
        // Extract identifier from user ID.
        guard let identifierMatch = mxIdString.firstMatch(of: /^@(.*?):.*$/) else {
            return nil
        }
        
        let identifier = identifierMatch.output.1
        
        // Return the identifier as-is if no transformations were needed.
        guard let lastHyphenIndex = identifier.lastIndex(of: "-") else {
            return UserDisplayName(String(identifier))
        }
        
        let IDENTIFIER_PART_SEPARATOR_DOT: Character = "."
        let IDENTIFIER_PART_SEPARATOR_HYPHEN: Character = "-"
        
        if isExternalTchapServer {
            // Handle external Tchap user case: replace single hyphen with '@'.
            if identifier.firstIndex(of: "-") == lastHyphenIndex {
                return UserDisplayName(identifier.replacingCharacters(in: lastHyphenIndex...lastHyphenIndex, with: "@"))
            } else {
                return UserDisplayName(String(identifier))
            }
        } else {
            var transformedIdentifier = String()
            var capitalizeNext = true
            for char in identifier[..<lastHyphenIndex] {
                if capitalizeNext, char == IDENTIFIER_PART_SEPARATOR_DOT || char == IDENTIFIER_PART_SEPARATOR_HYPHEN {
                    continue
                } else if char == IDENTIFIER_PART_SEPARATOR_DOT {
                    // Replace the dot character by space character
                    transformedIdentifier.append(" ")
                    // Capitalize next char after space
                    capitalizeNext = true
                } else if char == IDENTIFIER_PART_SEPARATOR_HYPHEN {
                    transformedIdentifier.append(char)
                    // Capitalize next char after hyphen
                    capitalizeNext = true
                } else if capitalizeNext {
                    transformedIdentifier.append(char.uppercased())
                    capitalizeNext = false
                } else {
                    transformedIdentifier.append(char)
                }
            }
            return UserDisplayName(transformedIdentifier)
        }
    }
    
    /// Create a room alias name with a prefix.
    ///
    /// - Parameters:
    ///   - prefix: the alias name prefix.
    ///
    /// - Returns: the suggested alias name.
 
    func createRoomAliasName(prefix: String) -> String {
        prefix.trimmingCharacters(in: .whitespaces).replacing(/[^a-zA-Z0-9]/, with: "") + String.randomAlphanumeric(length: 10)
    }
    
    /// Create a room alias with a prefix.
    ///
    /// - Parameters:
    ///   - sessionId: the user's id session.
    ///   - prefix: the alias name prefix.
    ///
    /// - Returns: the suggested alias.
    
    func createRoomAlias(sessionId: String, prefix: String) -> String {
        "\(createRoomAliasName(prefix: prefix))\(Self.MATRIXID_PARTS_SEPARATOR)\(MatrixIdFromString(sessionId).homeServerName)"
    }
}

extension String {
    /// Create a randon string composed of characters A..Z, a..z and 0..9..
    ///
    /// - Parameters:
    ///   - length: the number of characters of the generated string.
    ///
    /// - Returns: a random string.
    ///
    static func randomAlphanumeric(length: Int) -> String {
        let letters = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789"
        return String((0..<length).map { _ in letters.randomElement()! })
    }
}
