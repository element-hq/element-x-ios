//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomDirectorySearchScreenViewModelType = StateStoreViewModel<RoomDirectorySearchScreenViewState, RoomDirectorySearchScreenViewAction>

class RoomDirectorySearchScreenViewModel: RoomDirectorySearchScreenViewModelType, RoomDirectorySearchScreenViewModelProtocol {
    private let roomDirectorySearchProxy: RoomDirectorySearchProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let actionsSubject: PassthroughSubject<RoomDirectorySearchScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<RoomDirectorySearchScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
        
    init(clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         mediaProvider: MediaProviderProtocol) {
        roomDirectorySearchProxy = clientProxy.roomDirectorySearchProxy()
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: RoomDirectorySearchScreenViewState(), mediaProvider: mediaProvider)
        
        state.rooms = roomDirectorySearchProxy.resultsPublisher.value
        
        roomDirectorySearchProxy.resultsPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.rooms, on: self)
            .store(in: &cancellables)
        
        context.$viewState.map(\.bindings.searchString)
            // only listen to the search string when is not loading
            .combineLatest(context.$viewState.map(\.isLoading)
                .filter { $0 == false })
            .map(\.0)
            .debounceTextQueriesAndRemoveDuplicates()
            .sink { [weak self] query in
                self?.search(query: query)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomDirectorySearchScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .dismiss:
            actionsSubject.send(.dismiss)
        case .select(let room):
            if let alias = room.alias {
                actionsSubject.send(.selectAlias(alias))
            } else {
                actionsSubject.send(.selectRoomID(room.id))
            }
        case .reachedBottom:
            loadNextPage()
        }
    }
    
    // MARK: - Private
    
    private static let errorID = "roomDirectorySearchViewModelLoadingError"
    
    private func search(query: String?) {
        guard !state.isLoading else {
            return
        }
        
        state.rooms = []
        state.isLoading = true
        Task {
            switch await roomDirectorySearchProxy.search(query: query) {
            case .success:
                break
            case .failure:
                userIndicatorController.submitIndicator(UserIndicator(id: Self.errorID,
                                                                      type: .toast,
                                                                      title: L10n.screenRoomDirectorySearchLoadingError,
                                                                      iconName: "xmark"))
            }
            
            // Add a small delay to allow the rooms to be published,
            // otherwise you see the No Results text briefly.
            try? await Task.sleep(for: .milliseconds(50))
            state.isLoading = false
        }
    }
    
    private func loadNextPage() {
        guard !state.isLoading else {
            return
        }
        
        Task {
            state.isLoading = true
            let _ = await roomDirectorySearchProxy.nextPage()
            state.isLoading = false
        }
    }
}
