//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//
import Foundation

class MentionUsersCache {
    static let shared = MentionUsersCache()
    
    private init() { }
    
    private let queue = DispatchQueue(label: "com.app.MentionUsersCache", attributes: .concurrent)
    private var mentionUsersDisplayNameMap: [String: String] = [:]
    
    func addMentionUser(id: String, name: String) {
        queue.async(flags: .barrier) { [weak self] in
            self?.mentionUsersDisplayNameMap[id] = name
        }
    }
    
    func getMentionUserDisplayName(id: String) -> String? {
        var result: String?
        queue.sync {
            result = mentionUsersDisplayNameMap[id]
        }
        return result
    }
}
