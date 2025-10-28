//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SpaceSettingsScreenViewModelType = StateStoreViewModelV2<SpaceSettingsScreenViewState, SpaceSettingsScreenViewAction>

class SpaceSettingsScreenViewModel: SpaceSettingsScreenViewModelType, SpaceSettingsScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<SpaceSettingsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(initialViewState: SpaceSettingsScreenViewState(title: "SpaceSettings title",
                                                                  placeholder: "Enter something here",
                                                                  bindings: .init(composerText: "Initial composer text")))
    }
    
    // MARK: - Public
    
    override func process(viewAction: SpaceSettingsScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .done:
            break
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
