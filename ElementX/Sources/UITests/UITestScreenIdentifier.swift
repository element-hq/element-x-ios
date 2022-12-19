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

enum UITestScreenIdentifier: String {
    case login
    case serverSelection
    case serverSelectionNonModal
    case authenticationFlow
    case softLogout
    case analyticsPrompt
    case simpleRegular
    case simpleUpgrade
    case home
    case settings
    case bugReport
    case bugReportWithScreenshot
    case onboarding
    case roomPlainNoAvatar
    case roomEncryptedWithAvatar
    case roomSmallTimeline
    case roomSmallTimelineIncomingAndSmallPagination
    case roomSmallTimelineLargePagination
    case sessionVerification
    case userSessionScreen
    case roomDetailsScreen
    case roomMembersScreen
}

extension UITestScreenIdentifier: CustomStringConvertible {
    var description: String {
        rawValue.titlecased()
    }
}

extension UITestScreenIdentifier: CaseIterable { }

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
