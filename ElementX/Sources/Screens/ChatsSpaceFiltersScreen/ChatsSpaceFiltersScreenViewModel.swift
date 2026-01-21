//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ChatsSpaceFiltersScreenViewModelType = StateStoreViewModelV2<ChatsSpaceFiltersScreenViewState, ChatsSpaceFiltersScreenViewAction>

class ChatsSpaceFiltersScreenViewModel: ChatsSpaceFiltersScreenViewModelType, ChatsSpaceFiltersScreenViewModelProtocol, Identifiable {
    private let spaceService: SpaceServiceProxyProtocol
    
    private let actionsSubject: PassthroughSubject<ChatsSpaceFiltersScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ChatsSpaceFiltersScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    let id = UUID()
    
    init(spaceService: SpaceServiceProxyProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.spaceService = spaceService
        
        super.init(initialViewState: ChatsSpaceFiltersScreenViewState(bindings: .init()),
                   mediaProvider: mediaProvider)
        
        state.filters = spaceService.spaceFilterPublisher.value
        
        spaceService.spaceFilterPublisher.sink { [weak self] filters in
            self?.state.filters = filters
        }
        .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: ChatsSpaceFiltersScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .confirm(let filter):
            actionsSubject.send(.confirm(filter))
        case .cancel:
            actionsSubject.send(.cancel)
        }
    }
}
