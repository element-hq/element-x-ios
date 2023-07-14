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
    private let roomProxy: RoomProxyProtocol
    private let roomMemberProxy: RoomMemberProxyProtocol
    
    var callback: ((RoomMemberDetailsScreenViewModelAction) -> Void)?
    
    init(roomProxy: RoomProxyProtocol, roomMemberProxy: RoomMemberProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.roomProxy = roomProxy
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
            Task.detached {
                await self.roomProxy.updateMembers()
            }
        case .failure:
            state.bindings.alertInfo = .init(id: .unknown)
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
            Task.detached {
                await self.roomProxy.updateMembers()
            }
        case .failure:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }
}
