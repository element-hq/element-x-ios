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

enum InvitesViewModelAction {
    case openRoom(withIdentifier: String)
}

struct InvitesViewState: BindableState {
    var invites: [InvitesRoomDetails]?
    var bindings: InvitesViewStateBindings = .init()
}

struct InvitesViewStateBindings {
    var alertInfo: AlertInfo<Bool>?
}

struct InvitesRoomDetails {
    let roomDetails: RoomSummaryDetails
    var inviter: RoomMemberProxyProtocol?
    
    var isDirect: Bool {
        roomDetails.isDirect
    }
}

enum InvitesViewAction {
    case accept(InvitesRoomDetails)
    case decline(InvitesRoomDetails)
}
