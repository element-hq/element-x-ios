//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias DialPadScreenViewModelType = StateStoreViewModel<DialPadScreenViewState, DialPadScreenViewAction>

class DialPadScreenViewModel: DialPadScreenViewModelType, DialPadScreenViewModelProtocol {
    private let userSession: UserSessionProtocol
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<DialPadScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<DialPadScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.userSession = userSession
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: DialPadScreenViewState(), mediaProvider: userSession.mediaProvider)
    }
    
    override func process(viewAction: DialPadScreenViewAction) {
        switch viewAction {
        case .digit(let digit):
            state.bindings.phoneNumber += digit
        case .delete:
            if !state.bindings.phoneNumber.isEmpty {
                state.bindings.phoneNumber.removeLast()
            }
        case .dial:
            Task { await createRoom() }
        case .close:
            actionsSubject.send(.close)
        }
    }
    
    private func createRoom() async {
        guard !state.bindings.phoneNumber.isEmpty else { return }
        
        showLoadingIndicator()
        defer { hideLoadingIndicator() }
        
        // Reusing existing room-creation logic: naming the room after the number.
        // We create a public room (or private, as implementation detail isn't strictly specified, but phone-to-room typically implies a private chat or a specific room).
        // The prompt says "reuse Element X's existing room-creation logic".
        // StartChat/CreateRoom uses: private default. Let's stick to CreateRoom defaults.
        
        let roomName = state.bindings.phoneNumber
        
        switch await userSession.clientProxy.createRoom(name: roomName,
                                                        topic: nil,
                                                        isRoomPrivate: true,
                                                        isKnockingOnly: false,
                                                        userIDs: [],
                                                        avatarURL: nil,
                                                        aliasLocalPart: nil) {
        case .success(let roomID):
            guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
                state.bindings.alertInfo = AlertInfo(id: .failedCreatingRoom,
                                                     title: L10n.commonError,
                                                     message: L10n.screenStartChatErrorStartingChat)
                return
            }
            analytics.trackCreatedRoom(isDM: false)
            actionsSubject.send(.createdRoom(roomProxy))
            
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .failedCreatingRoom,
                                                 title: L10n.commonError,
                                                 message: L10n.screenStartChatErrorStartingChat)
        }
    }
    
    // MARK: - Loading Indicator
    
    private static let loadingIndicatorIdentifier = "\(DialPadScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
