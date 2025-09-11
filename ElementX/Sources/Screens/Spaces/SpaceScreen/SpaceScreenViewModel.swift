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
    private let spaceServiceProxy: SpaceServiceProxyProtocol
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<SpaceScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(spaceRoomListProxy: SpaceRoomListProxyProtocol,
         spaceServiceProxy: SpaceServiceProxyProtocol,
         selectedSpaceRoomPublisher: CurrentValuePublisher<String?, Never>,
         userSession: UserSessionProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.spaceServiceProxy = spaceServiceProxy
        clientProxy = userSession.clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: SpaceScreenViewState(space: spaceRoomListProxy.spaceRoomProxy,
                                                          rooms: spaceRoomListProxy.spaceRoomsPublisher.value,
                                                          selectedSpaceRoomID: selectedSpaceRoomPublisher.value),
                   mediaProvider: userSession.mediaProvider)
        
        spaceRoomListProxy.spaceRoomsPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.rooms, on: self)
            .store(in: &cancellables)
        
        // As the server is slow, we just let the screen automatically paginate everything in. We can
        // switch this to use the scroll position once Synapse receives some performance improvements.
        spaceRoomListProxy.paginationStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paginationState in
                switch paginationState {
                case .idle(let endReached):
                    self?.state.isPaginating = false
                    guard !endReached else { return }
                    Task { await spaceRoomListProxy.paginate() }
                case .loading:
                    self?.state.isPaginating = true
                }
            }
            .store(in: &cancellables)
        
        selectedSpaceRoomPublisher
            .weakAssign(to: \.state.selectedSpaceRoomID, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .spaceAction(.select(let spaceRoomProxy)):
            if spaceRoomProxy.isSpace {
                Task { await selectSpace(spaceRoomProxy) }
            } else {
                // No need to check the join state, the room flow will show an appropriately configured join screen if needed.
                actionsSubject.send(.selectRoom(roomID: spaceRoomProxy.id))
            }
        case .spaceAction(.join(let spaceRoomProxy)):
            Task { await join(spaceRoomProxy) }
        }
    }
    
    func stop() {
        // If we pop this screen with running join operations, we don't want them to do anything.
        state.joiningRoomIDs.removeAll()
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
    
    private func join(_ spaceRoomProxy: SpaceRoomProxyProtocol) async {
        state.joiningRoomIDs.insert(spaceRoomProxy.id)
        defer { state.joiningRoomIDs.remove(spaceRoomProxy.id) }
        
        guard case .success = await clientProxy.joinRoom(spaceRoomProxy.id, via: []) else {
            showFailureIndicator()
            return
        }
        
        // If multiple join operations are running, then only show the last one.
        guard state.joiningRoomIDs == [spaceRoomProxy.id] else { return }
        
        if spaceRoomProxy.isSpace {
            await selectSpace(spaceRoomProxy)
        } else {
            actionsSubject.send(.selectRoom(roomID: spaceRoomProxy.id))
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
