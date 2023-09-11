//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

enum UITestsScreenIdentifier: String {
    case login
    case serverConfirmationLogin
    case serverConfirmationRegister
    case serverSelection
    case serverSelectionNonModal
    case authenticationFlow
    case softLogout
    case waitlist
    case analyticsPrompt
    case analyticsSettingsScreen
    case migration
    case templateScreen
    case home
    case settings
    case bugReport
    case bugReportWithScreenshot
    case notificationSettingsScreen
    case notificationSettingsScreenMismatchConfiguration
    case onboarding
    case roomPlainNoAvatar
    case roomEncryptedWithAvatar
    case roomSmallTimeline
    case roomSmallTimelineWithReactions
    case roomSmallTimelineWithReadReceipts
    case roomSmallTimelineIncomingAndSmallPagination
    case roomSmallTimelineLargePagination
    case roomLayoutTop
    case roomLayoutMiddle
    case roomLayoutBottom
    case roomWithDisclosedPolls
    case roomWithUndisclosedPolls
    case sessionVerification
    case userSessionScreen
    case userSessionScreenReply
    case userSessionScreenRTE
    case roomDetailsScreen
    case roomDetailsScreenWithRoomAvatar
    case roomDetailsScreenWithEmptyTopic
    case roomDetailsScreenWithInvite
    case roomDetailsScreenDmDetails
    case roomEditDetails
    case roomEditDetailsReadOnly
    case roomMembersListScreen
    case roomMembersListScreenPendingInvites
    case roomMemberDetailsAccountOwner
    case roomMemberDetails
    case roomMemberDetailsIgnoredUser
    case roomNotificationSettingsDefaultSetting
    case roomNotificationSettingsCustomSetting
    case reportContent
    case startChat
    case startChatWithSearchResults
    case invites
    case invitesWithBadges
    case invitesNoInvites
    case inviteUsers
    case inviteUsersInRoom
    case inviteUsersInRoomExistingMembers
    case createRoom
    case createRoomNoUsers
    case createPoll
}

extension UITestsScreenIdentifier: CustomStringConvertible {
    var description: String {
        rawValue.titlecased()
    }
}

private extension String {
    func titlecased() -> String {
        replacingOccurrences(of: "([A-Z])",
                             with: " $1",
                             options: .regularExpression,
                             range: range(of: self))
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .capitalized
    }
}
