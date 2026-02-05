//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

/// The rule used for users wishing to join a room.
public enum JoinRule: Equatable, Hashable {
    /// Anyone can join the room without any prior action.
    case `public`
    /// A user who wishes to join the room must first receive an invite.
    case invite
    /// Users can join the room if they are invited, or they can request an invite to the room.
    ///
    /// They can be allowed (invited) or denied (kicked/banned) access.
    case knock
    /// Users can join the room if they are invited, or if they meet any of the  conditions described
    /// in a set of ``AllowRule``s.
    case restricted(rules: [AllowRule])
    /// Users can join the room if they are invited, or if they meet any of the conditions described
    /// in a set of ``AllowRule``s, or they can request an invite to the room.
    case knockRestricted(rules: [AllowRule])
    /// A custom join rule, up for interpretation by the consumer.
    case custom(rawValue: String)
    
    init(rustValue: MatrixRustSDK.JoinRule) {
        self = switch rustValue {
        case .public: .public
        case .invite: .invite
        case .knock: .knock
        case .private: .invite // Assume .private is .invite – private shouldn't be in used (see MSC4413).
        case .restricted(let rules): .restricted(rules: rules.map(AllowRule.init))
        case .knockRestricted(let rules): .knockRestricted(rules: rules.map(AllowRule.init))
        case .custom(let rawValue): .custom(rawValue: rawValue)
        }
    }
    
    var rustValue: MatrixRustSDK.JoinRule {
        switch self {
        case .public: .public
        case .invite: .invite
        case .knock: .knock
        case .restricted(rules: let rules): .restricted(rules: rules.map(\.rustValue))
        case .knockRestricted(rules: let rules): .knockRestricted(rules: rules.map(\.rustValue))
        case .custom(let rawValue): .custom(repr: rawValue)
        }
    }
}

/// An allow rule which defines a condition that allows joining a room.
public enum AllowRule: Equatable, Hashable {
    /// Only a member of the `room_id` Room can join the one this rule is used in.
    case roomMembership(roomID: String)
    /// A custom allow rule implementation, containing its JSON representation as a `String`.
    case custom(json: String)
    
    init(rustValue: MatrixRustSDK.AllowRule) {
        self = switch rustValue {
        case .roomMembership(let roomID): .roomMembership(roomID: roomID)
        case .custom(let json): .custom(json: json)
        }
    }
    
    var rustValue: MatrixRustSDK.AllowRule {
        switch self {
        case .roomMembership(let roomID): .roomMembership(roomId: roomID)
        case .custom(let json): .custom(json: json)
        }
    }
}
