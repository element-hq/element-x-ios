//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated struct UserHooks: Sendable {
    let roomScreenHook: RoomScreenHookProtocol
    let roomDetailsScreenHook: RoomDetailsScreenHookProtocol
    let roomMemberDetailsScreenHook: RoomMemberDetailsScreenHookProtocol
    let userProfileScreenHook: UserProfileScreenHookProtocol
    let recoveryKeyScreenHook: RecoveryKeyScreenHookProtocol
    let createRoomScreenHook: CreateRoomScreenHookProtocol
    let securityAndPrivacyScreenHook: SecurityAndPrivacyScreenHookProtocol
    let oAuthAccountSettingsPresenterHook: OAuthAccountSettingsPresenterHookProtocol
    let developerOptionsScreenHook: DeveloperOptionsScreenHookProtocol
    
    init(roomScreenHook: RoomScreenHookProtocol = DefaultRoomScreenHook(),
         roomDetailsScreenHook: RoomDetailsScreenHookProtocol = DefaultRoomDetailsScreenHook(),
         roomMemberDetailsScreenHook: RoomMemberDetailsScreenHookProtocol = DefaultRoomMemberDetailsScreenHook(),
         userProfileScreenHook: UserProfileScreenHookProtocol = DefaultUserProfileScreenHook(),
         recoveryKeyScreenHook: RecoveryKeyScreenHookProtocol = DefaultRecoveryKeyScreenHook(),
         createRoomScreenHook: CreateRoomScreenHookProtocol = DefaultCreateRoomScreenHook(),
         securityAndPrivacyScreenHook: SecurityAndPrivacyScreenHookProtocol = DefaultSecurityAndPrivacyScreenHook(),
         oAuthAccountSettingsPresenterHook: OAuthAccountSettingsPresenterHookProtocol = DefaultOAuthAccountSettingsPresenterHook(),
         developerOptionsScreenHook: DeveloperOptionsScreenHookProtocol = DefaultDeveloperOptionsScreenHook()) {
        self.roomScreenHook = roomScreenHook
        self.roomDetailsScreenHook = roomDetailsScreenHook
        self.roomMemberDetailsScreenHook = roomMemberDetailsScreenHook
        self.userProfileScreenHook = userProfileScreenHook
        self.recoveryKeyScreenHook = recoveryKeyScreenHook
        self.createRoomScreenHook = createRoomScreenHook
        self.securityAndPrivacyScreenHook = securityAndPrivacyScreenHook
        self.oAuthAccountSettingsPresenterHook = oAuthAccountSettingsPresenterHook
        self.developerOptionsScreenHook = developerOptionsScreenHook
    }
}
