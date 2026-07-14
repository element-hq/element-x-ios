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
    
    init(sdkUserProfile: MatrixRustSDK.UserProfile) {
        id = sdkUserProfile.userId
        displayName = sdkUserProfile.displayName
        avatarURL = sdkUserProfile.avatarUrl.flatMap(URL.init(string:))
        status = .init(rustStatus: sdkUserProfile.status, rustCall: sdkUserProfile.call)
    }
    
    init(sdkRoomHero: MatrixRustSDK.RoomHero) {
        id = sdkRoomHero.userId
        displayName = sdkRoomHero.displayName
        avatarURL = sdkRoomHero.avatarUrl.flatMap(URL.init(string:))
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

nonisolated struct UserStatus: Hashable {
    /// The status manually set by the user (if any).
    let userSet: UserSet?
    /// The status automatically set by Element Call (while in a call).
    let call: Call?
    
    /// The status that should be displayed on the user's profile.
    var displayed: DisplayedStatus? {
        // The user-set status takes precedence over the call indicator.
        userSet.map { .userSet($0) } ?? call.map { .inCall($0) }
    }
    
    nonisolated struct UserSet: Hashable {
        let text: String
        let emoji: Character
    }
    
    nonisolated struct Call: Hashable {
        let startDate: Date?
    }
    
    nonisolated enum DisplayedStatus: Hashable {
        case userSet(UserSet)
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
        userSet = nil
        call = nil
    }
    
    init(rustStatus: MatrixRustSDK.UserStatus?, rustCall: MatrixRustSDK.UserCall?) {
        userSet = rustStatus.map(UserSet.init)
        call = rustCall.map(Call.init)
    }
}

nonisolated extension UserStatus.UserSet {
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
        startDate = rustCall.callJoinedTs.map { Date(timeIntervalSince1970: Double($0)) }
    }
    
    var rustValue: MatrixRustSDK.UserCall {
        .init(callJoinedTs: startDate.map { UInt64($0.timeIntervalSince1970) })
    }
}

struct SearchUsersResults {
    let results: [UserProfile]
    let limited: Bool
}

extension SearchUsersResults {
    init(sdkResults: MatrixRustSDK.SearchUsersResults) {
        results = sdkResults.results.map(UserProfile.init)
        limited = sdkResults.limited
    }
}
