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
import UIKit

// MARK: - Coordinator

// MARK: View model

enum RoomDetailsViewModelAction {
    case requestMemberDetailsPresentation([RoomMemberProxyProtocol])
    case leftRoom
    case cancel
}

// MARK: View

struct RoomDetailsViewState: BindableState {
    let roomId: String
    let canonicalAlias: String?
    let isEncrypted: Bool
    let isDirect: Bool
    var title = ""
    var topic: String?
    var avatarURL: URL?
    let permalink: URL?
    var members: [RoomDetailsMember]
    
    var isLoadingMembers: Bool {
        members.isEmpty
    }

    var bindings: RoomDetailsViewStateBindings
}

struct RoomDetailsViewStateBindings {
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomDetailsErrorType>?
    var leaveRoomAlertItem: LeaveRoomAlertItem?
}

struct LeaveRoomAlertItem: AlertItem {
    enum RoomState {
        case empty
        case `public`
        case `private`
    }

    let state: RoomState
    let title = ElementL10n.roomProfileSectionMoreLeave
    let confirmationTitle = ElementL10n.actionLeave
    let cancelTitle = ElementL10n.actionCancel

    var subtitle: String {
        switch state {
        case .empty: return ElementL10n.roomDetailsLeaveEmptyRoomAlertSubtitle
        case .private: return ElementL10n.roomDetailsLeavePrivateRoomAlertSubtitle
        case .public: return ElementL10n.roomDetailsLeaveRoomAlertSubtitle
        }
    }
}

enum RoomDetailsViewAction {
    case processTapPeople
    case processTapLeave
    case confirmLeave
    case copyRoomLink
}

struct RoomDetailsMember: Identifiable, Equatable {
    let id: String
    let name: String?
    let avatarURL: URL?

    init(withProxy proxy: RoomMemberProxyProtocol) {
        id = proxy.userId
        name = proxy.displayName
        avatarURL = proxy.avatarURL
    }
}

enum RoomDetailsErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert(String)
    /// Leaving room has failed..
    case unknown
}
