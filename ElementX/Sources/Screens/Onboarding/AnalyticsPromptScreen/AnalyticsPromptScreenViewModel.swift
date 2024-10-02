//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias AnalyticsPromptScreenViewModelType = StateStoreViewModel<AnalyticsPromptScreenViewState, AnalyticsPromptScreenViewAction>

class AnalyticsPromptScreenViewModel: AnalyticsPromptScreenViewModelType, AnalyticsPromptScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<AnalyticsPromptScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<AnalyticsPromptScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    /// Initialize a view model with the specified prompt type and app display name.
    init(termsURL: URL) {
        let promptStrings = AnalyticsPromptScreenStrings(termsURL: termsURL)
        super.init(initialViewState: AnalyticsPromptScreenViewState(strings: promptStrings))
    }

    // MARK: - Public
    
    override func process(viewAction: AnalyticsPromptScreenViewAction) {
        switch viewAction {
        case .enable:
            actionsSubject.send(.enable)
        case .disable:
            actionsSubject.send(.disable)
        }
    }
}
