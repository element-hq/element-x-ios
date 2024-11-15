//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias KnockRequestsListScreenViewModelType = StateStoreViewModel<KnockRequestsListScreenViewState, KnockRequestsListScreenViewAction>

class KnockRequestsListScreenViewModel: KnockRequestsListScreenViewModelType, KnockRequestsListScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<KnockRequestsListScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<KnockRequestsListScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(initialViewState: KnockRequestsListScreenViewState(title: "KnockRequestsList title",
                                                                      placeholder: "Enter something here",
                                                                      bindings: .init(composerText: "Initial composer text")))
    }
    
    // MARK: - Public
    
    override func process(viewAction: KnockRequestsListScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .done:
            actionsSubject.send(.done)
        case .textChanged:
            MXLog.info("View model: composer text changed to: \(state.bindings.composerText)")
        }
    }
}
