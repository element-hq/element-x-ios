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

typealias RoomMemberDetailsScreenViewModelType = StateStoreViewModel<RoomMemberDetailsScreenViewState, RoomMemberDetailsScreenViewAction>

class RoomMemberDetailsScreenViewModel: RoomMemberDetailsScreenViewModelType, RoomMemberDetailsScreenViewModelProtocol {
    let roomMemberProxy: RoomMemberProxyProtocol
    
    var callback: ((RoomMemberDetailsScreenViewModelAction) -> Void)?
    
    init(roomMemberProxy: RoomMemberProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.roomMemberProxy = roomMemberProxy
        let initialViewState = RoomMemberDetailsScreenViewState(details: RoomMemberDetails(withProxy: roomMemberProxy),
                                                                bindings: .init())
        super.init(initialViewState: initialViewState, imageProvider: mediaProvider)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomMemberDetailsScreenViewAction) {
        switch viewAction {
        case .showUnignoreAlert:
            state.bindings.ignoreUserAlert = .init(action: .unignore)
        case .showIgnoreAlert:
            state.bindings.ignoreUserAlert = .init(action: .ignore)
        case .ignoreConfirmed:
            Task { await ignoreUser() }
        case .unignoreConfirmed:
            Task { await unignoreUser() }
        }
    }

    // MARK: - Private

    @MainActor
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

    @MainActor
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
