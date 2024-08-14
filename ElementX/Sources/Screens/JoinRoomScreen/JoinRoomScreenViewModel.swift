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
    private let via: [String]
    private let allowKnocking: Bool // For preview tests only, actions aren't sent.
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var roomPreviewDetails: RoomPreviewDetails?
    private var roomProxy: RoomProxyProtocol?
    
    private let actionsSubject: PassthroughSubject<JoinRoomScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<JoinRoomScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomID: String,
         via: [String],
         allowKnocking: Bool = false,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         networkMonitor: NetworkMonitorProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomID = roomID
        self.via = via
        self.allowKnocking = allowKnocking
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: JoinRoomScreenViewState(roomID: roomID),
                   dependencies: .init(imageProvider: mediaProvider, networkMonitor: networkMonitor))
        
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
            Task { await updateRoomDetails() }
        }
        
        // Using only the preview API isn't enough as it's not capable
        // of giving us information for non-joined rooms (at least not on synapse)
        // See if we known about the room locally and, if so, have that
        // take priority over the preview one.
        
        if let roomProxy = await clientProxy.roomForIdentifier(roomID) {
            self.roomProxy = roomProxy
            await updateRoomDetails()
        }
        
        switch await clientProxy.roomPreviewForIdentifier(roomID, via: via) {
        case .success(let roomPreviewDetails):
            self.roomPreviewDetails = roomPreviewDetails
            await updateRoomDetails()
        case .failure(.roomPreviewIsPrivate):
            break // Handled by the mode, we don't need an error indicator.
        case .failure:
            userIndicatorController.submitIndicator(UserIndicator(title: L10n.errorUnknown))
        }
    }
    
    private func updateRoomDetails() async {
        let name = roomProxy?.name ?? roomPreviewDetails?.name
        let inviter = await roomProxy?.inviter.flatMap(RoomInviterDetails.init)
        state.roomDetails = JoinRoomScreenRoomDetails(name: name,
                                                      topic: roomProxy?.topic ?? roomPreviewDetails?.topic,
                                                      canonicalAlias: roomProxy?.canonicalAlias ?? roomPreviewDetails?.canonicalAlias,
                                                      avatar: roomProxy?.avatar ?? .room(id: roomID, name: name ?? "", avatarURL: roomPreviewDetails?.avatarURL),
                                                      memberCount: UInt(roomProxy?.activeMembersCount ?? Int(roomPreviewDetails?.memberCount ?? 0)),
                                                      inviter: inviter)
        
        updateMode()
    }
    
    private func updateMode() {
        if roomProxy?.membership == .invited || roomPreviewDetails?.isInvited ?? false { // Check invites first to show Accept/Decline buttons on public rooms.
            state.mode = .invited
        } else if roomProxy?.isPublic ?? false || roomPreviewDetails?.isPublic ?? false {
            state.mode = .join
        } else if roomPreviewDetails?.canKnock ?? false, allowKnocking { // Knocking is not supported yet, the flag is purely for preview tests.
            state.mode = .knock
        } else {
            // If everything else fails fallback to showing the join button and
            // letting the server figure it out.
            state.mode = .join
        }
    }
    
    private func joinRoom() async {
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        // Prioritise joining by the alias and letting the homeserver do the right thing
        if let alias = state.roomDetails?.canonicalAlias {
            switch await clientProxy.joinRoomAlias(alias) {
            case .success:
                actionsSubject.send(.joined)
            case .failure(let error):
                MXLog.error("Failed joining room alias: \(alias) with error: \(error)")
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            }
        } else {
            switch await clientProxy.joinRoom(roomID, via: via) {
            case .success:
                actionsSubject.send(.joined)
            case .failure(let error):
                MXLog.error("Failed joining room id: \(roomID) with error: \(error)")
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            }
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
