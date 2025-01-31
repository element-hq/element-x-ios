//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Tagged

struct ZPosts: Codable {
    let posts: [ZPost]
    
    enum CodingKeys: String, CodingKey {
        case posts
    }
}

struct ZPost: Codable, Identifiable {
    let id: Tagged<Self, String>
    let userId: String
    let zid: String
    let createdAt: String
    let updatedAt: String
    let signedMessage: String
    let unsignedMessage: String
    let text: String
    let walletAddress: String
    let worldZid: String?
    let imageUrl: String?
    let arweaveId: String
    let replyTo: String?
    let conversationId: String?
    let user: User
    let postsMeowsSummary: PostsMeowsSummary
    let meows: [Meow]
    let replies: [Reply]
    
    enum CodingKeys: String, CodingKey {
        case id, userId, zid, createdAt, updatedAt, signedMessage, unsignedMessage, text, walletAddress, worldZid, imageUrl, arweaveId, replyTo, conversationId, user, postsMeowsSummary, meows, replies
    }
}

extension ZPost: Equatable {
    public static func == (lhs: ZPost, rhs: ZPost) -> Bool {
        lhs.id == rhs.id
    }
}

extension ZPost: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct User: Codable {
    let id: String
    let profileId: String
    let handle: String
    let profileSummary: ProfileSummary
}

struct ProfileSummary: Codable {
    let id: String
    let firstName: String
    let lastName: String
    let primaryEmail: String
    let profileImage: String
}

struct PostsMeowsSummary: Codable {
    let postId: String
    let totalMeowAmount: String
}

struct Meow: Codable {
    // Define properties if needed; the example shows an empty array
}

struct Reply: Codable {
    let id: String
    let replyTo: String
}
