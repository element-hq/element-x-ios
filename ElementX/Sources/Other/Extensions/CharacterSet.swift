//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension CharacterSet {
    private static let urlAllowedSets: [CharacterSet] = [
        .urlUserAllowed,
        .urlPasswordAllowed,
        .urlHostAllowed,
        .urlPathAllowed,
        .urlQueryAllowed,
        .urlFragmentAllowed
    ]
    
    static let urlAllowedCharacters: CharacterSet = {
        // Start by including hash, which isn't in any URL set
        // Then include all URL-legal characters
        var result = CharacterSet(charactersIn: "#")
        for set in urlAllowedSets {
            result.formUnion(set)
        }
        return result
    }()
    
    static let matrixUserIDAllowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789._=-/@:")
    static let roomAliasAllowedCharacters = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyz0123456789!$&‘()*+/;=?@[]-._:#")
    
    static let punctuationWithoutClosingBracketCharacters: CharacterSet = {
        var baseSet: CharacterSet = .punctuationCharacters
        baseSet.remove(")")
        return baseSet
    }()
}
