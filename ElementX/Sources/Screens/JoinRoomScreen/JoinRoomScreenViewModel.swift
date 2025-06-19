//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    
    private var roomPreview: RoomPreviewProxyProtocol?
    private var room: RoomProxyType?
    private var isLoadingPreview = true
    private var membershipStateChangeCancellable: AnyCancellable?
    
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
        
        clientProxy.hideInviteAvatarsPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.hideInviteAvatars, on: self)
            .store(in: &cancellables)
        
        context.$viewState.map(\.mode)
            .removeDuplicates()
            .sink { mode in
                switch mode {
                case .invited:
                    appSettings.seenInvites.insert(roomID)
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
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
        case .forget:
            Task { await forgetRoom() }
        case .declineInvite:
            showDeclineInviteConfirmationAlert()
        case .cancelKnock:
            showCancelKnockConfirmationAlert()
        case .dismiss:
            actionsSubject.send(.dismiss)
        case .declineInviteAndBlock(let userID):
            Task { await showDeclineAndBlockConfirmationAlert(userID: userID) }
        }
    }
    
    func stop() {
        hideLoadingIndicator()
    }
    
    // MARK: - Private
    
    private func loadRoomDetails() async {
        showLoadingIndicator()
        
        await updateRoom()
        
        switch await clientProxy.roomPreviewForIdentifier(roomID, via: via) {
        case .success(let roomPreview):
            isLoadingPreview = false
            self.roomPreview = roomPreview
            await updateRoomDetails()
        case .failure(.roomPreviewIsPrivate):
            // Handled by the mode, we don't need an error indicator.
            isLoadingPreview = false
        case .failure:
            hideLoadingIndicator()
            state.bindings.alertInfo = .init(id: .loadingError,
                                             title: L10n.commonError,
                                             message: L10n.screenJoinRoomLoadingAlertMessage,
                                             primaryButton: .init(title: L10n.actionTryAgain) { [weak self] in Task { await self?.loadRoomDetails() }},
                                             secondaryButton: .init(title: L10n.actionCancel, role: .cancel) { [weak self] in self?.actionsSubject.send(.dismiss) })
        }
        
        hideLoadingIndicator()
        
        await updateRoomDetails()
    }
    
    private func updateRoom() async {
        // Using only the preview API isn't enough as it's not capable
        // of giving us information for non-joined rooms (at least not on synapse)
        // See if we known about the room locally and, if so, have that
        // take priority over the preview one.
        if let room = await clientProxy.roomForIdentifier(roomID) {
            self.room = room
            await updateRoomDetails()
        }
    }
    
    private func updateRoomDetails() async {
        membershipStateChangeCancellable = nil
        var roomInfo: BaseRoomInfoProxyProtocol?
        var inviter: RoomInviterDetails?
        
        switch room {
        case .joined(let joinedRoomProxy):
            roomInfo = joinedRoomProxy.infoPublisher.value
        case .invited(let invitedRoomProxy):
            inviter = invitedRoomProxy.inviter.map(RoomInviterDetails.init)
            roomInfo = invitedRoomProxy.info
        case .knocked(let knockedRoomProxy):
            roomInfo = knockedRoomProxy.info
            membershipStateChangeCancellable = clientProxy
                .staticRoomSummaryProvider
                .roomListPublisher
                .compactMap { summaries -> Void? in
                    guard let roomSummary = summaries.first(where: { $0.id == roomInfo?.id }),
                          roomSummary.room.membership() != .knocked else {
                        return nil
                    }
                    return ()
                }
                .sink { [weak self] in
                    Task { await self?.loadRoomDetails() }
                }
        case .banned(let bannedRoomProxy):
            roomInfo = bannedRoomProxy.info
        default:
            break
        }

        let info = roomPreview?.info ?? roomInfo
        let avatar: RoomAvatar? = if let avatar = info?.avatar {
            avatar
        } else if let displayName = info?.displayName {
            .room(id: roomID, name: displayName, avatarURL: nil)
        } else {
            nil
        }
        state.roomDetails = JoinRoomScreenRoomDetails(name: info?.displayName,
                                                      topic: info?.topic,
                                                      canonicalAlias: info?.canonicalAlias,
                                                      avatar: avatar,
                                                      memberCount: info?.joinedMembersCount,
                                                      inviter: inviter,
                                                      isDirect: info?.isDirect)
        
        await updateMode()
    }
    
    private func updateMode() async {
        if isLoadingPreview {
            state.mode = .loading
            return
        }
        
        if roomPreview == nil, room == nil {
            state.mode = .unknown
            return
        }
        
        if let roomPreview {
            let membershipDetails = await roomPreview.ownMembershipDetails
            
            switch roomPreview.info.membership {
            case .invited:
                state.mode = .invited(isDM: state.roomDetails?.isDirect == true && state.roomDetails?.memberCount == 1)
            case .knocked:
                state.mode = .knocked
            case .banned:
                state.mode = .banned(sender: membershipDetails?.senderRoomMember?.displayName ?? membershipDetails?.senderRoomMember?.userID,
                                     reason: membershipDetails?.ownRoomMember.membershipChangeReason)
            default:
                switch roomPreview.info.joinRule {
                case .private, .invite:
                    state.mode = .inviteRequired
                case .knock, .knockRestricted:
                    state.mode = appSettings.knockingEnabled ? .knockable : .joinable
                case .restricted:
                    state.mode = .restricted
                default:
                    state.mode = .joinable
                }
            }
        } else if let room {
            switch room {
            case .invited:
                state.mode = .invited(isDM: state.roomDetails?.isDirect == true && state.roomDetails?.memberCount == 1)
            case .knocked:
                state.mode = .knocked
            case .banned:
                state.mode = .banned(sender: nil, reason: nil)
            default:
                state.mode = .joinable
            }
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
                appSettings.seenInvites.remove(roomID)
                actionsSubject.send(.joined)
            case .failure(let error):
                switch error {
                case .forbiddenAccess:
                    MXLog.error("Failed joining room alias: \(alias) forbidden access")
                    state.mode = .forbidden
                case .invalidInvite:
                    MXLog.error("Failed joining room alias: \(alias) invalid invite")
                    state.bindings.alertInfo = .init(id: .invalidInvite, title: L10n.dialogTitleError, message: L10n.errorInvalidInvite)
                default:
                    MXLog.error("Failed joining room alias: \(alias) with error: \(error)")
                    userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                }
            }
        } else {
            switch await clientProxy.joinRoom(roomID, via: via) {
            case .success:
                appSettings.seenInvites.remove(roomID)
                actionsSubject.send(.joined)
            case .failure(let error):
                switch error {
                case .forbiddenAccess:
                    MXLog.error("Failed joining room id: \(roomID) forbidden access")
                    state.mode = .forbidden
                case .invalidInvite:
                    MXLog.error("Failed joining room id: \(roomID) invalid invite")
                    state.bindings.alertInfo = .init(id: .invalidInvite, title: L10n.dialogTitleError, message: L10n.errorInvalidInvite)
                default:
                    MXLog.error("Failed joining room id: \(roomID) with error: \(error)")
                    userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
                }
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
                // The room should become knocked through the sync
                await loadRoomDetails()
            case .failure(let error):
                MXLog.error("Failed knocking room alias: \(alias) with error: \(error)")
                userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            }
        } else {
            switch await clientProxy.knockRoom(roomID,
                                               via: via,
                                               message: state.bindings.knockMessage.isBlank ? nil : state.bindings.knockMessage) {
            case .success:
                // The room should become knocked through the sync
                await loadRoomDetails()
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
                                         secondaryButton: .init(title: L10n.actionDecline, role: .destructive) { Task { await self.declineInvite() } })
    }
    
    private func showCancelKnockConfirmationAlert() {
        state.bindings.alertInfo = .init(id: .cancelKnock,
                                         title: L10n.screenJoinRoomCancelKnockAlertTitle,
                                         message: L10n.screenJoinRoomCancelKnockAlertDescription,
                                         primaryButton: .init(title: L10n.actionNo, role: .cancel, action: nil),
                                         secondaryButton: .init(title: L10n.screenJoinRoomCancelKnockAlertConfirmation, role: .destructive) { Task { await self.cancelKnock() } })
    }
    
    private func showDeclineAndBlockConfirmationAlert(userID: String) async {
        if await clientProxy.isReportRoomSupported {
            actionsSubject.send(.presentDeclineAndBlock(userID: userID))
        } else {
            state.bindings.alertInfo = .init(id: .declineInviteAndBlock,
                                             title: L10n.screenJoinRoomDeclineAndBlockAlertTitle,
                                             message: L10n.screenJoinRoomDeclineAndBlockAlertMessage(userID),
                                             primaryButton: .init(title: L10n.actionCancel, role: .cancel, action: nil),
                                             secondaryButton: .init(title: L10n.screenJoinRoomDeclineAndBlockAlertConfirmation, role: .destructive) { Task { await self.declineAndBlock(userID: userID) } })
        }
    }
    
    private func declineAndBlock(userID: String) async {
        guard await declineInvite() else {
            return
        }
        // The decline alert and the view are already dismissed at this point so we can dispatch this separately as a best effort
        // but only if the decline invite was succesfull
        Task {
            await clientProxy.ignoreUser(userID)
        }
    }
    
    @discardableResult
    private func declineInvite() async -> Bool {
        defer {
            userIndicatorController.retractIndicatorWithId(roomID)
        }
        
        userIndicatorController.submitIndicator(UserIndicator(id: roomID, type: .modal, title: L10n.commonLoading, persistent: true))
        
        guard case let .invited(roomProxy) = room else {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return false
        }
        
        let result = await roomProxy.rejectInvitation()
        
        if case .failure = result {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return false
        }
        
        appSettings.seenInvites.remove(roomID)
        
        actionsSubject.send(.dismiss)
        return true
    }
    
    private func cancelKnock() async {
        defer {
            userIndicatorController.retractIndicatorWithId(roomID)
        }
        
        userIndicatorController.submitIndicator(UserIndicator(id: roomID, type: .modal, title: L10n.commonLoading, persistent: true))
        
        guard case let .knocked(roomProxy) = room else {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return
        }
        
        let result = await roomProxy.cancelKnock()
        
        if case .failure = result {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
        } else {
            actionsSubject.send(.dismiss)
        }
    }
    
    private func forgetRoom() async {
        defer {
            userIndicatorController.retractIndicatorWithId(roomID)
        }
        
        userIndicatorController.submitIndicator(UserIndicator(id: roomID, type: .modal, title: L10n.commonLoading, persistent: true))
        
        guard case let .banned(roomProxy) = room else {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
            return
        }
        
        let result = await roomProxy.forgetRoom()
        
        if case .failure = result {
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
        } else {
            actionsSubject.send(.dismiss)
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
