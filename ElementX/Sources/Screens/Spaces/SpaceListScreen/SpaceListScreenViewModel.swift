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
    
    private let actionsSubject: PassthroughSubject<SpaceListScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceListScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(userSession: UserSessionProtocol, spaceServiceProxy: SpaceServiceProxyProtocol) {
        self.spaceServiceProxy = spaceServiceProxy
        
        super.init(initialViewState: SpaceListScreenViewState(userID: userSession.clientProxy.userID,
                                                              joinedSpaces: spaceServiceProxy.joinedSpacesPublisher.value,
                                                              joinedRoomsCount: 0,
                                                              bindings: .init()),
                   mediaProvider: userSession.mediaProvider)
        
        spaceServiceProxy.joinedSpacesPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.joinedSpaces, on: self)
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
        case .spaceAction(.select(let spaceRoom)):
            actionsSubject.send(.selectSpace(spaceRoom))
        case .spaceAction(.join(let spaceRoom)):
            #warning("Implement joining.")
        case .showSettings:
            actionsSubject.send(.showSettings)
        }
    }
}
