//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceListScreenViewModelType = StateStoreViewModelV2<SpaceListScreenViewState, SpaceListScreenViewAction>

class SpaceListScreenViewModel: SpaceListScreenViewModelType, SpaceListScreenViewModelProtocol {
    private let spaceServiceProxy: SpaceServiceProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<SpaceListScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceListScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userSession: UserSessionProtocol,
         selectedSpaceSubject: CurrentValuePublisher<String?, Never>,
         userIndicatorController: UserIndicatorControllerProtocol) {
        spaceServiceProxy = userSession.clientProxy.spaceService
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: SpaceListScreenViewState(userID: userSession.clientProxy.userID,
                                                              joinedSpaces: spaceServiceProxy.joinedSpacesPublisher.value,
                                                              bindings: .init()),
                   mediaProvider: userSession.mediaProvider)
        
        spaceServiceProxy.joinedSpacesPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.joinedSpaces, on: self)
            .store(in: &cancellables)
        
        selectedSpaceSubject
            .weakAssign(to: \.state.selectedSpaceID, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.userDisplayNamePublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userDisplayName, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceListScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .spaceAction(.select(let spaceRoomProxy)):
            Task { await selectSpace(spaceRoomProxy) }
        case .spaceAction(.join(let spaceRoom)):
            #warning("Implement joining.")
        case .showSettings:
            actionsSubject.send(.showSettings)
        }
    }
    
    // MARK: - Private
    
    private func selectSpace(_ spaceRoomProxy: SpaceRoomProxyProtocol) async {
        switch await spaceServiceProxy.spaceRoomList(for: spaceRoomProxy) {
        case .success(let spaceRoomListProxy):
            actionsSubject.send(.selectSpace(spaceRoomListProxy))
        case .failure(let error):
            MXLog.error("Unable to select space: \(error)")
            showFailureIndicator()
        }
    }
    
    // MARK: - Indicators
    
    private static var failureIndicatorID: String { "\(Self.self)-Failure" }
    
    private func showFailureIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.failureIndicatorID,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
}
