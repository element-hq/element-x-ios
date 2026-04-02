//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomThreadListScreenViewModelType = StateStoreViewModelV2<RoomThreadListScreenViewState, RoomThreadListScreenViewAction>

class RoomThreadListScreenViewModel: RoomThreadListScreenViewModelType, RoomThreadListScreenViewModelProtocol {
    private let threadListServiceProxy: RoomThreadListServiceProxyProtocol
    
    private var isOldestItemVisible = false
    
    private let actionsSubject: PassthroughSubject<RoomThreadListScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomThreadListScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(threadListServiceProxy: RoomThreadListServiceProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.threadListServiceProxy = threadListServiceProxy
        
        super.init(initialViewState: .init(bindings: .init()), mediaProvider: mediaProvider)
        
        updateItems(self.threadListServiceProxy.itemsPublisher.value)
        
        threadListServiceProxy.itemsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] items in
                self?.updateItems(items)
            }
            .store(in: &cancellables)
        
        threadListServiceProxy.paginationStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] paginationState in
                guard let self else { return }
                state.isPaginating = paginationState == .loading
                Task { await self.paginateIfNecessary(paginationState: paginationState) }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomThreadListScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .oldestItemDidAppear:
            isOldestItemVisible = true
            
            Task {
                await paginateIfNecessary(paginationState: threadListServiceProxy.paginationStatePublisher.value)
            }
        case .oldestItemDidDisappear:
            isOldestItemVisible = false
        case .tappedThread(let threadRootEventID):
            actionsSubject.send(.presentThread(threadRootEventID: threadRootEventID))
        }
    }
    
    // MARK: - Private
    
    private func paginateIfNecessary(paginationState: RoomThreadListPaginationState) async {
        if isOldestItemVisible, case .idle(endReached: false) = paginationState {
            _ = await threadListServiceProxy.paginate()
        }
    }
    
    private func updateItems(_ items: [RoomThreadListItem]) {
        state.items = items
    }
}
