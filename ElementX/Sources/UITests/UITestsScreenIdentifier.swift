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
    case appLockFlow
    case appLockFlowAlternateWindow
    case appLockFlowDisabled
    case appLockFlowDisabledAlternateWindow
    case appLockSetupFlow
    case appLockSetupFlowMandatory
    case appLockSetupFlowUnlock
    case authenticationFlow
    case bugReport
    case createPoll
    case createRoom
    case createRoomNoUsers
    case invites
    case login
    case roomLayoutBottom
    case roomLayoutMiddle
    case roomLayoutTop
    case roomLayoutHighlight
    case roomMembersListScreenPendingInvites
    case roomPlainNoAvatar
    case roomRolesAndPermissionsFlow
    case roomSmallTimeline
    case roomSmallTimelineIncomingAndSmallPagination
    case roomSmallTimelineLargePagination
    case roomSmallTimelineWithReactions
    case roomSmallTimelineWithReadReceipts
    case roomWithDisclosedPolls
    case roomWithOutgoingPolls
    case roomWithUndisclosedPolls
    case serverSelection
    case sessionVerification
    case startChat
    case startChatWithSearchResults
    case templateScreen
    case userSessionScreen
    case userSessionScreenReply
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
