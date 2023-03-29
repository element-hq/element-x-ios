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
        let initialViewState = RoomMemberDetailsViewState(details: RoomMemberDetails(withProxy: roomMemberProxy),
                                                          bindings: .init())
        super.init(initialViewState: initialViewState, imageProvider: mediaProvider)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomMemberDetailsViewAction) async {
        switch viewAction {
        case .showUnignoreAlert:
            state.bindings.ignoreUserAlert = .init(action: .unignore)
        case .showIgnoreAlert:
            state.bindings.ignoreUserAlert = .init(action: .ignore)
        case .copyUserLink:
            copyUserLink()
        case .ignoreConfirmed:
            await ignoreUser()
        case .unignoreConfirmed:
            await unignoreUser()
        }
    }

    // MARK: - Private

    private func copyUserLink() {
        if let userLink = state.details.permalink {
            UIPasteboard.general.url = userLink
            ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(title: L10n.commonLinkCopiedToClipboard))
        } else {
            ServiceLocator.shared.userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
        }
    }

    private func ignoreUser() async {
        state.isProcessingIgnoreRequest = true
        let result = await roomMemberProxy.ignoreUser()
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            state.details.isIgnored = true
        case .failure:
            state.bindings.errorAlert = .init()
        }
    }

    private func unignoreUser() async {
        state.isProcessingIgnoreRequest = true
        let result = await roomMemberProxy.unignoreUser()
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            state.details.isIgnored = false
        case .failure:
            state.bindings.errorAlert = .init()
        }
    }
}
