//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

final class RoomMemberProxy: RoomMemberProxyProtocol {
    private let member: RoomMember
    
    init(member: RoomMember) {
        self.member = member
    }
    
    var userID: String { member.userId }
    
    var displayName: String? { member.displayName }
    
    var disambiguatedDisplayName: String? {
        guard let displayName else {
            return nil
        }
        
        return member.isNameAmbiguous ? "\(displayName) (\(userID))" : displayName
    }
    
    var avatarURL: URL? { member.avatarUrl.flatMap(URL.init(string:)) }
    
    var membership: MembershipState { member.membership }
    
    var membershipChangeReason: String? { member.membershipChangeReason }
    
    var isIgnored: Bool { member.isIgnored }
    
    var powerLevel: Int { Int(member.powerLevel) }
    
    var role: RoomMemberRole { member.suggestedRoleForPowerLevel }
}
