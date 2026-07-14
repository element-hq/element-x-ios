//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

nonisolated struct UserProfile: Hashable, Identifiable {
    let id: String
    let displayName: String?
    let avatarURL: URL?
    let status: UserStatus
    
    init(userID: String, displayName: String? = nil, avatarURL: URL? = nil, status: UserStatus = .init()) {
        id = userID
        self.displayName = displayName
        self.avatarURL = avatarURL
        self.status = status
    }
    
    init(member: RoomMemberDetails) {
        id = member.id
        displayName = member.isBanned ? nil : member.name
        avatarURL = member.isBanned ? nil : member.avatarURL
        status = member.status
    }
    
    init(sender: TimelineItemSender) {
        id = sender.id
        displayName = sender.displayName
        avatarURL = sender.avatarURL
        status = sender.status
    }
    
    init(rustUserProfile: MatrixRustSDK.UserProfile) {
        id = rustUserProfile.userId
        displayName = rustUserProfile.displayName
        avatarURL = rustUserProfile.avatarUrl.flatMap(URL.init(string:))
        status = .init(rustStatus: rustUserProfile.status, rustCall: rustUserProfile.call)
    }
    
    init(rustRoomHero: MatrixRustSDK.RoomHero) {
        id = rustRoomHero.userId
        displayName = rustRoomHero.displayName
        avatarURL = rustRoomHero.avatarUrl.flatMap(URL.init(string:))
        status = .init() // Requires https://github.com/matrix-org/matrix-rust-sdk/pull/6733
    }
    
    init(member: RoomMemberProxyProtocol) {
        self.init(member: RoomMemberDetails(withProxy: member))
    }
    
    /// A user is meant to be "verified" when the GET profile returns back either the display name or the avatar
    /// If isn't we aren't sure that the related matrix id really exists.
    var isVerified: Bool {
        displayName != nil || avatarURL != nil
    }
}

// MARK: - Status

/// A user's status, created from a combination of their manually set status along with the call status indicator.
nonisolated struct UserStatus: Hashable {
    /// The raw status that is manually set by the user (if any).
    let raw: Raw?
    /// The call status indicator automatically set by Element Call (while in a call).
    let call: Call?
    
    /// The status that should be displayed on the user's profile.
    var displayed: Displayed? {
        // The user-set status takes precedence over the call indicator.
        raw.map { .userSet($0) } ?? call.map { .inCall($0) }
    }
    
    /// A status that is manually set by the user.
    nonisolated struct Raw: Hashable {
        let text: String
        let emoji: Character
    }
    
    /// The call status indicator automatically set by Element Call.
    nonisolated struct Call: Hashable {
        /// When the user joined the call, if known.
        let joinedDate: Date?
    }
    
    /// The status displayed in the UI.
    nonisolated enum Displayed: Hashable {
        case userSet(Raw)
        case inCall(Call)
        
        var text: String {
            switch self {
            case .userSet(let userSet): userSet.text
            case .inCall: L10n.commonOnACall
            }
        }
        
        var emoji: Character {
            switch self {
            case .userSet(let userSet): userSet.emoji
            case .inCall: "🎧"
            }
        }
    }
}

nonisolated extension UserStatus {
    init() {
        raw = nil
        call = nil
    }
    
    init(rustStatus: MatrixRustSDK.UserStatus?, rustCall: MatrixRustSDK.UserCall?) {
        raw = rustStatus.map(Raw.init)
        call = rustCall.map(Call.init)
    }
}

nonisolated extension UserStatus.Raw {
    init(rustStatus: MatrixRustSDK.UserStatus) {
        text = rustStatus.text
        emoji = Character(rustStatus.emoji)
    }
    
    var rustValue: MatrixRustSDK.UserStatus {
        .init(emoji: String(emoji), text: text)
    }
}

nonisolated extension UserStatus.Call {
    init(rustCall: MatrixRustSDK.UserCall) {
        joinedDate = rustCall.callJoinedTs.map { Date(timeIntervalSince1970: Double($0)) }
    }
    
    var rustValue: MatrixRustSDK.UserCall {
        .init(callJoinedTs: joinedDate.map { UInt64($0.timeIntervalSince1970) })
    }
}

// MARK: - Search Results

struct SearchUsersResults {
    let results: [UserProfile]
    let limited: Bool
}

extension SearchUsersResults {
    init(rustResults: MatrixRustSDK.SearchUsersResults) {
        results = rustResults.results.map(UserProfile.init)
        limited = rustResults.limited
    }
}
