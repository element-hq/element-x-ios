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

enum JoinRoomScreenInteractionMode {
    case unknown
    case invited
    case join
    case knock
}

struct JoinRoomScreenViewState: BindableState {
    // Maybe use room summary details or similar here??
    let roomID: String
    
    var roomDetails: RoomPreviewDetails?
    
    var mode: JoinRoomScreenInteractionMode {
        guard let roomDetails else {
            return .unknown
        }
        
        if roomDetails.isInvited {
            return .invited
        }
        
        if roomDetails.isPublic {
            return .join
        }
        
        // Knocking is not supported yet, treat it as .unknown
        // if roomDetails.canKnock {
        //     return .knock
        // }
        
        return .unknown
    }
    
    var bindings = JoinRoomScreenViewStateBindings()
    
    var title: String {
        roomDetails?.name ?? L10n.screenJoinRoomTitleNoPreview
    }
}

struct JoinRoomScreenViewStateBindings {
    var alertInfo: AlertInfo<JoinRoomScreenAlertType>?
}

enum JoinRoomScreenAlertType {
    case declineInvite
}

enum JoinRoomScreenViewAction {
    case knock
    case join
    case acceptInvite
    case declineInvite
}
