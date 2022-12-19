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

import SwiftUI

typealias RoomDetailsViewModelType = StateStoreViewModel<RoomDetailsViewState, RoomDetailsViewAction>

class RoomDetailsViewModel: RoomDetailsViewModelType, RoomDetailsViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let roomProxy: RoomProxyProtocol
    private let mediaProvider: MediaProviderProtocol

    // MARK: Public

    var callback: ((RoomDetailsViewModelAction) -> Void)?

    // MARK: - Setup

    init(roomProxy: RoomProxyProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.roomProxy = roomProxy
        self.mediaProvider = mediaProvider
        super.init(initialViewState: .init(roomId: roomProxy.id,
                                           isEncrypted: roomProxy.isEncrypted,
                                           isDirect: roomProxy.isDirect,
                                           roomTitle: roomProxy.displayName ?? roomProxy.name ?? "Unknown Room",
                                           roomTopic: roomProxy.topic,
                                           members: [],
                                           bindings: .init()))

        Task {
            switch await roomProxy.members() {
            case .success(let members):
                state.members = members.map { RoomDetailsMember(withProxy: $0) }
            case .failure(let error):
                MXLog.debug("Failed to retrieve room members: \(error)")
                state.bindings.alertInfo = AlertInfo(id: .alert(ElementL10n.unknownError))
            }
        }

        if let avatarURL = roomProxy.avatarURL {
            Task {
                if case let .success(avatar) = await mediaProvider.loadImageFromURLString(avatarURL,
                                                                                          avatarSize: .room(on: .details)) {
                    state.roomAvatar = avatar
                }
            }
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomDetailsViewAction) async {
        switch viewAction {
        case .processTapPeople:
            callback?(.peopleTapped)
        }
    }
}
