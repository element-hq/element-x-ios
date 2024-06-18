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

typealias GlobalSearchScreenViewModelType = StateStoreViewModel<GlobalSearchScreenViewState, GlobalSearchScreenViewAction>

class GlobalSearchScreenViewModel: GlobalSearchScreenViewModelType, GlobalSearchScreenViewModelProtocol {
    private let roomSummaryProvider: RoomSummaryProviderProtocol
    
    private var actionsSubject: PassthroughSubject<GlobalSearchScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<GlobalSearchScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(roomSummaryProvider: RoomSummaryProviderProtocol,
         imageProvider: ImageProviderProtocol) {
        self.roomSummaryProvider = roomSummaryProvider
        
        super.init(initialViewState: GlobalSearchScreenViewState(bindings: .init(searchQuery: "")),
                   imageProvider: imageProvider)
        
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
            switch summary {
            case .empty:
                return nil
            case .invalidated(let details), .filled(let details):
                return GlobalSearchRoom(id: details.id,
                                        name: details.name,
                                        alias: details.canonicalAlias,
                                        avatar: details.avatar)
            }
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
