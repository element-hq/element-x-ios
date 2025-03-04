//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias CreateFeedScreenViewModelType = StateStoreViewModel<CreateFeedScreenViewState, CreateFeedScreenViewAction>

class CreateFeedScreenViewModel: CreateFeedScreenViewModelType, CreateFeedScreenViewModelProtocol {
    
    private let clientProxy: ClientProxyProtocol
        
    private var actionsSubject: PassthroughSubject<CreateFeedScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<CreateFeedScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(clientProxy: ClientProxyProtocol, mediaProvider: MediaProviderProtocol) {
        self.clientProxy = clientProxy
        
        super.init(initialViewState: .init(bindings: .init()), mediaProvider: mediaProvider)
    }
}
