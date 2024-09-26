//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    case autoUpdatingTimeline
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
