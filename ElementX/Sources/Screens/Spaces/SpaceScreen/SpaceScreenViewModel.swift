//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceScreenViewModelType = StateStoreViewModelV2<SpaceScreenViewState, SpaceScreenViewAction>

class SpaceScreenViewModel: SpaceScreenViewModelType, SpaceScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<SpaceScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(spaceRoomList: SpaceRoomListProxyProtocol, mediaProvider: MediaProviderProtocol) {
        super.init(initialViewState: SpaceScreenViewState(space: spaceRoomList.spaceRoom,
                                                          rooms: spaceRoomList.spaceRoomsPublisher.value),
                   mediaProvider: mediaProvider)
        
        spaceRoomList.spaceRoomsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] rooms in
                self?.state.rooms = rooms
            }
            // .weakAssign(to: \.state.rooms, on: self)
            .store(in: &cancellables)
        
        spaceRoomList.paginationStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paginationState in
                switch paginationState {
                case .idle(let endReached):
                    self?.state.isPaginating = false
                    guard !endReached else { return }
                    Task { await spaceRoomList.paginate() }
                case .loading:
                    self?.state.isPaginating = true
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .spaceAction(.select(let spaceRoom)):
            if spaceRoom.isSpace {
                actionsSubject.send(.selectSpace(spaceRoom))
            } else {
                #warning("Implement joining")
            }
        case .spaceAction(.join(let spaceID)):
            #warning("Implement joining.")
        }
    }
}
