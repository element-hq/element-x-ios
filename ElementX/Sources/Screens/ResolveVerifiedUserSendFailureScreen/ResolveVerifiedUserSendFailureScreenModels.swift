//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum ResolveVerifiedUserSendFailureScreenViewModelAction {
    case dismiss
}

struct ResolveVerifiedUserSendFailureScreenViewState: BindableState {
    var currentFailure: TimelineItemSendFailure.VerifiedUser
    var currentMemberDisplayName: String
    var isYou: Bool
    
    var title: String {
        switch currentFailure {
        case .hasUnsignedDevice:
            isYou ? L10n.screenResolveSendFailureYouUnsignedDeviceTitle : L10n.screenResolveSendFailureUnsignedDeviceTitle(currentMemberDisplayName)
        case .changedIdentity:
            L10n.screenResolveSendFailureChangedIdentityTitle(currentMemberDisplayName)
        }
    }
    
    var subtitle: String {
        switch currentFailure {
        case .hasUnsignedDevice:
            isYou ? L10n.screenResolveSendFailureYouUnsignedDeviceSubtitle : L10n.screenResolveSendFailureUnsignedDeviceSubtitle(currentMemberDisplayName, currentMemberDisplayName)
        case .changedIdentity:
            L10n.screenResolveSendFailureChangedIdentitySubtitle(currentMemberDisplayName)
        }
    }
    
    var primaryButtonTitle: String {
        switch currentFailure {
        case .hasUnsignedDevice: L10n.screenResolveSendFailureUnsignedDevicePrimaryButtonTitle
        case .changedIdentity: L10n.screenResolveSendFailureChangedIdentityPrimaryButtonTitle
        }
    }
}

enum ResolveVerifiedUserSendFailureScreenViewAction {
    case resolveAndResend
    case resend
    case cancel
}
