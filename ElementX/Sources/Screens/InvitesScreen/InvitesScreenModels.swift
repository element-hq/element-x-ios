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

enum InvitesScreenViewModelAction {
    case openRoom(withIdentifier: String)
}

struct InvitesScreenViewState: BindableState {
    var invites: [InvitesScreenRoomDetails] = []
    var bindings: InvitesScreenViewStateBindings = .init()
}

struct InvitesScreenViewStateBindings {
    var alertInfo: AlertInfo<Bool>?
}

struct InvitesScreenRoomDetails: Identifiable {
    let roomDetails: RoomSummaryDetails
    var inviter: RoomMemberProxyProtocol?
    var isUnread: Bool
    
    var isDirect: Bool {
        roomDetails.isDirect
    }
    
    var id: String {
        roomDetails.id
    }
}

enum InvitesScreenViewAction {
    case accept(InvitesScreenRoomDetails)
    case decline(InvitesScreenRoomDetails)
}
