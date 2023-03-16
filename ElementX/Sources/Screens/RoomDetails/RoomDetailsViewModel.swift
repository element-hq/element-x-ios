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
    private let roomProxy: RoomProxyProtocol
    private var members: [RoomMemberProxy] = [] {
        didSet {
            state.members = members.map { RoomDetailsMember(withProxy: $0) }
        }
    }
    
    var callback: ((RoomDetailsViewModelAction) -> Void)?
    
    init(roomProxy: RoomProxyProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.roomProxy = roomProxy
        super.init(initialViewState: .init(roomId: roomProxy.id,
                                           canonicalAlias: roomProxy.canonicalAlias,
                                           isEncrypted: roomProxy.isEncrypted,
                                           isDirect: roomProxy.isDirect,
                                           title: roomProxy.displayName ?? roomProxy.name ?? "Unknown Room",
                                           topic: roomProxy.topic,
                                           avatarURL: roomProxy.avatarURL,
                                           permalink: roomProxy.permalink,
                                           members: [],
                                           bindings: .init()),
                   imageProvider: mediaProvider)

        Task {
            switch await roomProxy.members() {
            case .success(let members):
                self.members = members
            case .failure(let error):
                MXLog.error("Failed retrieving room members: \(error)")
                state.bindings.alertInfo = AlertInfo(id: .alert(ElementL10n.unknownError))
            }
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomDetailsViewAction) async {
        switch viewAction {
        case .processTapPeople:
            callback?(.requestMemberDetailsPresentation(members))
        case .copyRoomLink:
            copyRoomLink()
        case .processTapLeave:
            state.bindings.leaveRoomAlertItem = LeaveRoomAlertItem()
        case .confirmLeave:
            await leaveRoom()
        }
    }
    
    // MARK: - Private

    private static let leaveRoomLoadingId = "LeaveRoomLoading"
    
    private func copyRoomLink() {
        if let roomLink = state.permalink {
            UIPasteboard.general.url = roomLink
            ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(title: ElementL10n.linkCopiedToClipboard))
        } else {
            ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(title: ElementL10n.unknownError))
        }
    }

    private func leaveRoom() async {
        ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(id: Self.leaveRoomLoadingId, type: .modal, title: ElementL10n.loading, persistent: true))
        let result = await roomProxy.leaveRoom()
        ServiceLocator.shared.userIndicatorController.retractIndicatorWithId(Self.leaveRoomLoadingId)
        switch result {
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .unknown)
        case .success:
            callback?(.leaveRoom)
        }
    }
}
