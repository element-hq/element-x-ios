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

typealias RoomMemberDetailsViewModelType = StateStoreViewModel<RoomMemberDetailsViewState, RoomMemberDetailsViewAction>

class RoomMemberDetailsViewModel: RoomMemberDetailsViewModelType, RoomMemberDetailsViewModelProtocol {
    let roomMemberProxy: RoomMemberProxyProtocol

    var callback: ((RoomMemberDetailsViewModelAction) -> Void)?

    init(roomMemberProxy: RoomMemberProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.roomMemberProxy = roomMemberProxy
        let initialViewState = RoomMemberDetailsViewState(userID: roomMemberProxy.userID,
                                                          name: roomMemberProxy.displayName ?? "",
                                                          avatarURL: roomMemberProxy.avatarURL,
                                                          isAccountOwner: roomMemberProxy.isAccountOwner,
                                                          permalink: roomMemberProxy.permalink,
                                                          isIgnored: roomMemberProxy.isIgnored,
                                                          bindings: .init())
        super.init(initialViewState: initialViewState, imageProvider: mediaProvider)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomMemberDetailsViewAction) async {
        switch viewAction {
        case .unblockTapped:
            await unblockUser()
        case .blockTapped:
            state.bindings.blockUserAlertItem = .init()
        case .copyUserLink:
            copyUserLink()
        case .blockConfirmed:
            await blockUser()
        }
    }

    // MARK: - Private

    private func copyUserLink() {
        if let userLink = state.permalink {
            UIPasteboard.general.url = userLink
            ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(title: ElementL10n.linkCopiedToClipboard))
        } else {
            ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(title: ElementL10n.unknownError))
        }
    }

    private func blockUser() async {
        switch await roomMemberProxy.blockUser() {
        case .success:
            state.isIgnored.toggle()
        case .failure:
            // TODO: Localise strings
            state.bindings.errorAlert = .init(title: "Error", message: "Unknown Error")
        }
    }

    private func unblockUser() async {
        switch await roomMemberProxy.unblockUser() {
        case .success:
            state.isIgnored.toggle()
        case .failure:
            // TODO: Localise strings
            state.bindings.errorAlert = .init(title: "Error", message: "Unknown Error")
        }
    }
}
