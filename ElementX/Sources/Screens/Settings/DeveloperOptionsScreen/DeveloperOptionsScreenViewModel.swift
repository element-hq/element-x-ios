//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias DeveloperOptionsScreenViewModelType = StateStoreViewModel<DeveloperOptionsScreenViewState, DeveloperOptionsScreenViewAction>

class DeveloperOptionsScreenViewModel: DeveloperOptionsScreenViewModelType, DeveloperOptionsScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<DeveloperOptionsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<DeveloperOptionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(developerOptions: DeveloperOptionsProtocol, elementCallBaseURL: URL, isUsingNativeSlidingSync: Bool) {
        let bindings = DeveloperOptionsScreenViewStateBindings(developerOptions: developerOptions)
        let state = DeveloperOptionsScreenViewState(elementCallBaseURL: elementCallBaseURL, isUsingNativeSlidingSync: isUsingNativeSlidingSync, bindings: bindings)
        
        super.init(initialViewState: state)
    }
    
    override func process(viewAction: DeveloperOptionsScreenViewAction) {
        switch viewAction {
        case .clearCache:
            actionsSubject.send(.clearCache)
        }
    }
}
