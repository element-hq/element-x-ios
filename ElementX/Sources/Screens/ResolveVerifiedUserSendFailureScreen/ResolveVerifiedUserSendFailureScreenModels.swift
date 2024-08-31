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

enum ResolveVerifiedUserSendFailureScreenViewModelAction {
    case dismiss
}

struct ResolveVerifiedUserSendFailureScreenViewState: BindableState {
    var currentFailure: TimelineItemSendFailure.VerifiedUser
    var currentMemberDisplayName: String
    
    var title: String {
        switch currentFailure {
        case .hasUnsignedDevice: UntranslatedL10n.screenRoomSendFailureUnsignedDeviceResolveTitle(currentMemberDisplayName)
        case .changedIdentity: UntranslatedL10n.screenRoomSendFailureIdentityChangedResolveTitle(currentMemberDisplayName)
        }
    }
    
    var subtitle: String {
        switch currentFailure {
        case .hasUnsignedDevice: UntranslatedL10n.screenRoomSendFailureUnsignedDeviceResolveSubtitle(currentMemberDisplayName,
                                                                                                     currentMemberDisplayName)
        case .changedIdentity: UntranslatedL10n.screenRoomSendFailureIdentityChangedResolveSubtitle(currentMemberDisplayName)
        }
    }
    
    var primaryButtonTitle: String {
        switch currentFailure {
        case .hasUnsignedDevice: UntranslatedL10n.screenRoomSendFailureUnsignedDeviceResolvePrimaryButtonTitle
        case .changedIdentity: UntranslatedL10n.screenRoomSendFailureIdentityChangedResolvePrimaryButtonTitle
        }
    }
}

enum ResolveVerifiedUserSendFailureScreenViewAction {
    case resolveAndResend
    case resend
    case cancel
}
