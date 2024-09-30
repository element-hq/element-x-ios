//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias GlobalSearchScreenViewModelType = StateStoreViewModel<GlobalSearchScreenViewState, GlobalSearchScreenViewAction>

class GlobalSearchScreenViewModel: GlobalSearchScreenViewModelType, GlobalSearchScreenViewModelProtocol {
    private let roomSummaryProvider: RoomSummaryProviderProtocol
    
    private var actionsSubject: PassthroughSubject<GlobalSearchScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<GlobalSearchScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomSummaryProvider: RoomSummaryProviderProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.roomSummaryProvider = roomSummaryProvider
        
        super.init(initialViewState: GlobalSearchScreenViewState(bindings: .init(searchQuery: "")),
                   mediaProvider: mediaProvider)
        
        roomSummaryProvider.roomListPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] summaries in
                self?.updateRooms(with: summaries)
            }
            .store(in: &cancellables)
        
        context.$viewState
            .map(\.bindings.searchQuery)
            .removeDuplicates()
            .sink { [weak self] searchQuery in
                self?.roomSummaryProvider.setFilter(.search(query: searchQuery))
            }
            .store(in: &cancellables)
        
        updateRooms(with: roomSummaryProvider.roomListPublisher.value)
    }
    
    // MARK: - Public
    
    override func process(viewAction: GlobalSearchScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .dismiss:
            actionsSubject.send(.dismiss)
            roomSummaryProvider.setFilter(.all(filters: [])) // This is a shared provider
        case .select(let roomID):
            actionsSubject.send(.select(roomID: roomID))
        case .reachedTop:
            updateVisibleRange(edge: .top)
        case .reachedBottom:
            updateVisibleRange(edge: .bottom)
        }
    }
    
    // MARK: - Private
    
    private func updateRooms(with summaries: [RoomSummary]) {
        state.rooms = summaries.compactMap { summary in
            GlobalSearchRoom(id: summary.id,
                             name: summary.name,
                             alias: summary.canonicalAlias,
                             avatar: summary.avatar)
        }
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
