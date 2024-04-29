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

import Combine
import SwiftUI

typealias JoinRoomScreenViewModelType = StateStoreViewModel<JoinRoomScreenViewState, JoinRoomScreenViewAction>

class JoinRoomScreenViewModel: JoinRoomScreenViewModelType, JoinRoomScreenViewModelProtocol {
    private let roomID: String
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<JoinRoomScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<JoinRoomScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomID: String,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomID = roomID
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: JoinRoomScreenViewState(roomID: roomID), imageProvider: mediaProvider)
        
        Task {
            await loadRoomDetails()
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: JoinRoomScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .knock:
            break
        case .join:
            Task { await joinRoom() }
        case .acceptInvite:
            Task { await joinRoom() }
        case .declineInvite:
            showDeclineInviteConfirmationAlert()
        }
    }
    
    func stop() {
        hideLoadingIndicator()
    }
    
    // MARK: - Private
    
    private func loadRoomDetails() async {
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        switch await clientProxy.roomPreviewForIdentifier(roomID) {
        case .success(let roomDetails):
            state.roomDetails = roomDetails
        case .failure:
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
        }
    }
    
    private func joinRoom() async {
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        switch await clientProxy.joinRoom(roomID) {
        case .success:
            actionsSubject.send(.joined)
        case .failure(let error):
            MXLog.error("Failed joining room with error: \(error)")
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
        }
    }
    
    private func showDeclineInviteConfirmationAlert() {
        guard let roomDetails = state.roomDetails else {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return
        }
        
        let roomName = roomDetails.name ?? roomID
        state.bindings.alertInfo = .init(id: .declineInvite,
                                         title: L10n.screenInvitesDeclineChatTitle,
                                         message: L10n.screenInvitesDeclineChatMessage(roomName),
                                         primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                         secondaryButton: .init(title: L10n.actionDecline, role: .destructive, action: { Task { await self.declineInvite() } }))
    }
    
    private func declineInvite() async {
        defer {
            userIndicatorController.retractIndicatorWithId(roomID)
        }
        
        userIndicatorController.submitIndicator(UserIndicator(id: roomID, type: .modal, title: L10n.commonLoading, persistent: true))
        
        guard let roomProxy = await clientProxy.roomForIdentifier(roomID) else {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return
        }
        
        let result = await roomProxy.rejectInvitation()
        
        if case .failure = result {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
        }
    }
    
    private static let loadingIndicatorIdentifier = "\(JoinRoomScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: false, allowsInteraction: true),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: .seconds(0.25))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
