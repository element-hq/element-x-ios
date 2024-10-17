//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias JoinRoomScreenViewModelType = StateStoreViewModel<JoinRoomScreenViewState, JoinRoomScreenViewAction>

class JoinRoomScreenViewModel: JoinRoomScreenViewModelType, JoinRoomScreenViewModelProtocol {
    private let roomID: String
    private let via: [String]
    private let appSettings: AppSettings
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var roomPreviewDetails: RoomPreviewDetails?
    private var room: RoomProxyType?
    
    private let actionsSubject: PassthroughSubject<JoinRoomScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<JoinRoomScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomID: String,
         via: [String],
         appSettings: AppSettings,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomID = roomID
        self.via = via
        self.appSettings = appSettings
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: JoinRoomScreenViewState(roomID: roomID), mediaProvider: mediaProvider)
        
        Task {
            await loadRoomDetails()
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: JoinRoomScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .knock:
            Task { await knockRoom() }
        case .join:
            Task { await joinRoom() }
        case .acceptInvite:
            Task { await joinRoom() }
        case .declineInvite:
            showDeclineInviteConfirmationAlert()
        case .cancelKnock:
            // TODO: implement once available
            break
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
        
        if let room = await clientProxy.roomForIdentifier(roomID) {
            self.room = room
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
        var roomProxy: RoomProxyProtocol?
        var inviter: RoomInviterDetails?
        
        switch room {
        case .joined(let joinedRoomProxy):
            roomProxy = joinedRoomProxy
        case .invited(let invitedRoomProxy):
            inviter = await invitedRoomProxy.inviter.flatMap(RoomInviterDetails.init)
            roomProxy = invitedRoomProxy
        case .knocked(let knockedRoomProxy):
            roomProxy = knockedRoomProxy
        default:
            break
        }
        
        let name = roomProxy?.name ?? roomPreviewDetails?.name
        state.roomDetails = JoinRoomScreenRoomDetails(name: name,
                                                      topic: roomProxy?.topic ?? roomPreviewDetails?.topic,
                                                      canonicalAlias: roomProxy?.canonicalAlias ?? roomPreviewDetails?.canonicalAlias,
                                                      avatar: roomProxy?.avatar ?? .room(id: roomID, name: name ?? "", avatarURL: roomPreviewDetails?.avatarURL),
                                                      memberCount: UInt(roomProxy?.activeMembersCount ?? Int(roomPreviewDetails?.memberCount ?? 0)),
                                                      inviter: inviter)
        
        updateMode()
    }
    
    private func updateMode() {
        if case .knocked = room {
            state.mode = .knocked
            return
        }
        
        // Check invites first to show Accept/Decline buttons on public rooms.
        if case .invited = room {
            state.mode = .invited
            return
        }
        
        if roomPreviewDetails?.isInvited ?? false {
            state.mode = .invited
            return
        }
        
        if roomPreviewDetails?.canKnock ?? false, appSettings.knockingEnabled {
            state.mode = .knock
        } else {
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
    
    private func knockRoom() async {
        showLoadingIndicator()
        
        defer {
            hideLoadingIndicator()
        }
        
        if let alias = state.roomDetails?.canonicalAlias {
            switch await clientProxy.knockRoomAlias(alias,
                                                    message: state.bindings.knockMessage.isBlank ? nil : state.bindings.knockMessage) {
            case .success:
                state.mode = .knocked
            case .failure(let error):
                MXLog.error("Failed knocking room alias: \(alias) with error: \(error)")
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            }
        } else {
            switch await clientProxy.knockRoom(roomID,
                                               message: state.bindings.knockMessage.isBlank ? nil : state.bindings.knockMessage) {
            case .success:
                state.mode = .knocked
            case .failure(let error):
                MXLog.error("Failed knocking room id: \(roomID) with error: \(error)")
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
        
        guard case let .invited(roomProxy) = room else {
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
