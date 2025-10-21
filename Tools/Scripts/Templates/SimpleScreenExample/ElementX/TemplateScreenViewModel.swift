//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias TemplateScreenViewModelType = StateStoreViewModelV2<TemplateScreenViewState, TemplateScreenViewAction>

class TemplateScreenViewModel: TemplateScreenViewModelType, TemplateScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<TemplateScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<TemplateScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(initialViewState: TemplateScreenViewState(title: "Template title",
                                                             placeholder: "Enter something here",
                                                             bindings: .init(composerText: "Initial composer text")))
    }
    
    // MARK: - Public
    
    override func process(viewAction: TemplateScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .done:
            actionsSubject.send(.done)
        case .textChanged:
            MXLog.info("View model: composer text changed to: \(state.bindings.composerText)")
        case .incrementCounter:
            Task {
                try await Task.sleep(for: .seconds(.random(in: 1.0...2.0)))
                state.counter += 1
            }
        case .decrementCounter:
            Task {
                try await Task.sleep(for: .seconds(.random(in: 1.0...2.0)))
                state.counter -= 1
            }
        }
    }
}
