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
    case cancel
}

// MARK: View

struct RoomDetailsViewState: BindableState {
    let roomId: String
    var roomTitle = ""
    var roomAvatar: UIImage?
    var members: [RoomDetailsMember]

    var bindings: RoomDetailsViewStateBindings
}

struct RoomDetailsViewStateBindings {
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomDetailsErrorType>?
}

enum RoomDetailsErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert(String)
}

enum RoomDetailsViewAction {
    case selectMember(id: String)
    case cancel
}

struct RoomDetailsMember: Identifiable, Equatable {
    let id: String

    let name: String?

    var avatar: UIImage?

    static func placeholder(id: String) -> RoomDetailsMember {
        RoomDetailsMember(id: id,
                       name: "Placeholder user name",
                       avatar: UIImage(systemName: "photo"))
    }
}
