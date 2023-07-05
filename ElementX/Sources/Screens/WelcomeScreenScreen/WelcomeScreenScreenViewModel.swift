//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

typealias WelcomeScreenScreenViewModelType = StateStoreViewModel<WelcomeScreenScreenViewState, WelcomeScreenScreenViewAction>

class WelcomeScreenScreenViewModel: WelcomeScreenScreenViewModelType, WelcomeScreenScreenViewModelProtocol {
    let appSettings: AppSettings
    private var actionsSubject: PassthroughSubject<WelcomeScreenScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<WelcomeScreenScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(appSettings: AppSettings = ServiceLocator.shared.settings) {
        self.appSettings = appSettings
        super.init(initialViewState: WelcomeScreenScreenViewState())
    }
    
    // MARK: - Public
    
    override func process(viewAction: WelcomeScreenScreenViewAction) {
        switch viewAction {
        case .doneTapped:
            actionsSubject.send(.dismiss)
        case .appeared:
            appSettings.hasShownWelcomeScreen = true
        }
    }
}
