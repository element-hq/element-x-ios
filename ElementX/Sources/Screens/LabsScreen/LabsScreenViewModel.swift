//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias LabsScreenViewModelType = StateStoreViewModelV2<LabsScreenViewState, LabsScreenViewAction>

class LabsScreenViewModel: LabsScreenViewModelType, LabsScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<LabsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<LabsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(labsOptions: LabsOptionsProtocol) {
        let bindings = LabsScreenViewStateBindings(labsOptions: labsOptions)
        let state = LabsScreenViewState(bindings: bindings)
        
        super.init(initialViewState: state)
    }
    
    override func process(viewAction: LabsScreenViewAction) {
        switch viewAction {
        case .clearCache:
            actionsSubject.send(.clearCache)
        }
    }
}
