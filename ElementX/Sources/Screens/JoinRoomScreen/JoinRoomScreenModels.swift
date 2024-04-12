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

enum JoinRoomScreenViewModelAction {
    case joined
    case cancelled
}

struct JoinRoomScreenViewState: BindableState {
    // Maybe use room summary details or similar here??
    let roomID: String
    let roomName: String
    let avatarURL: URL?
    
    let interaction: JoinRoomScreenInteraction
    
    var isJoining = false
    
    var bindings = JoinRoomScreenViewStateBindings()
    
    var title: String {
        switch interaction {
        case .knock:
            L10n.screenJoinRoomTitleKnock
        case .join, .invited:
            L10n.screenJoinRoomTitleNoPreview
        }
    }
    
    var subtitle: String {
        switch interaction {
        case .knock:
            L10n.screenJoinRoomSubtitleKnock
        case .join, .invited:
            L10n.screenJoinRoomSubtitleNoPreview
        }
    }
}

struct JoinRoomScreenViewStateBindings {
    var alertInfo: AlertInfo<JoinRoomScreenAlertType>?
}

enum JoinRoomScreenAlertType {
    case joinFailed
}

enum JoinRoomScreenInteraction {
    case knock
    case join
    case invited
}

enum JoinRoomScreenViewAction {
    case knock
    case join
    case acceptInvite
    case declineInvite
}
