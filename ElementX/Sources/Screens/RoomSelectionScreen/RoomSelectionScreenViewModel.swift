//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomSelectionScreenViewModelType = StateStoreViewModel<RoomSelectionScreenViewState, RoomSelectionScreenViewAction>

class RoomSelectionScreenViewModel: RoomSelectionScreenViewModelType, RoomSelectionScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let roomSummaryProvider: RoomSummaryProviderProtocol
    
    private var actionsSubject: PassthroughSubject<RoomSelectionScreenViewModelAction, Never> = .init()
    
    var actionsPublisher: AnyPublisher<RoomSelectionScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(clientProxy: ClientProxyProtocol,
         roomSummaryProvider: RoomSummaryProviderProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.clientProxy = clientProxy
        self.roomSummaryProvider = roomSummaryProvider
        
        super.init(initialViewState: RoomSelectionScreenViewState(), mediaProvider: mediaProvider)
        
        roomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateRooms()
            }
            .store(in: &cancellables)
        
        context.$viewState
            .map(\.bindings.searchQuery)
            .removeDuplicates()
            .sink { [weak self] searchQuery in
                if searchQuery.isEmpty {
                    self?.roomSummaryProvider.setFilter(.all(filters: []))
                } else {
                    self?.roomSummaryProvider.setFilter(.search(query: searchQuery))
                }
            }
            .store(in: &cancellables)
        
        updateRooms()
    }
    
    override func process(viewAction: RoomSelectionScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.dismiss)
            roomSummaryProvider.setFilter(.all(filters: []))
        case .confirm:
            guard let selectedRoomID = state.selectedRoomID else {
                return
            }
            
            actionsSubject.send(.confirm(roomID: selectedRoomID))
        case .selectRoom(let roomID):
            state.selectedRoomID = roomID
        case .reachedTop:
            updateVisibleRange(edge: .top)
        case .reachedBottom:
            updateVisibleRange(edge: .bottom)
        }
    }
    
    // MARK: - Private
    
    private func updateRooms() {
        var rooms = [RoomSelectionRoom]()
        
        for summary in roomSummaryProvider.roomListPublisher.value {
            rooms.append(.init(id: summary.id,
                               title: summary.name,
                               description: summary.roomListDescription,
                               avatar: summary.avatar))
        }
        
        state.rooms = rooms
    }
    
    /// The actual range values don't matter as long as they contain the lower
    /// or upper bounds. updateVisibleRange is a hybrid API that powers both
    /// sliding sync visible range update and list paginations
    /// For lists other than the home screen one we don't care about visible ranges,
    /// we just need the respective bounds to be there to trigger a next page load or
    /// a reset to just one page
    private func updateVisibleRange(edge: UIRectEdge) {
        switch edge {
        case .top:
            roomSummaryProvider.updateVisibleRange(0..<0)
        case .bottom:
            let roomCount = roomSummaryProvider.roomListPublisher.value.count
            roomSummaryProvider.updateVisibleRange(roomCount..<roomCount)
        default:
            break
        }
    }
}
