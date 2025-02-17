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

struct ZPostDetails: Codable {
    let post: ZPost
    
    enum CodingKeys: String, CodingKey {
        case post
    }
}

struct ZPostReplies: Codable {
    let replies: [ZPost]
    
    enum CodingKeys: String, CodingKey {
        case replies
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
    let postsMeowsSummary: PostsMeowsSummary?
    let meows: [Meow]?
    let replies: [Reply]?
    let replyToPost: ReplyToPost?
    
    enum CodingKeys: String, CodingKey {
        case id, userId, zid, createdAt, updatedAt, signedMessage, unsignedMessage, text, walletAddress, worldZid, imageUrl, arweaveId, replyTo, conversationId, user, postsMeowsSummary, meows, replies, replyToPost
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
    let primaryEmail: String?
    let profileImage: String
}

extension ProfileSummary {
    var fullName: String {
        "\(firstName) \(lastName)".trim()
    }
}

struct PostsMeowsSummary: Codable {
    let postId: String
    let totalMeowAmount: String
}

extension PostsMeowsSummary {
    func meowCount(decimal: Int) -> String {
        let mDecimal = decimal > 0 ? decimal : 18
        guard let number = Decimal(string: totalMeowAmount) else { return totalMeowAmount }
        
        // Compute divisor using NSDecimalNumber for precision
        let divisor = NSDecimalNumber(decimal: pow(10 as Decimal, mDecimal))
        let result = number / divisor.decimalValue
        
        return NSDecimalNumber(decimal: result).stringValue // Converts to string and removes trailing .0
    }
}

struct Meow: Codable {
    let id: String
    let postId: String
    let amount: String
    let createdAt: String?
    let userId:String?
}

struct Reply: Codable {
    let id: String
    let replyTo: String
}

struct ReplyToPost: Codable {
    let id: String
    let userId: String
    let zid: String
    let createdAt: String
    let text: String
    let arweaveId: String
    let user: User
}
