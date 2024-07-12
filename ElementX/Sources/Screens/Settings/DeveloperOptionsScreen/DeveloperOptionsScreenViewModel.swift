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

typealias DeveloperOptionsScreenViewModelType = StateStoreViewModel<DeveloperOptionsScreenViewState, DeveloperOptionsScreenViewAction>

class DeveloperOptionsScreenViewModel: DeveloperOptionsScreenViewModelType, DeveloperOptionsScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<DeveloperOptionsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<DeveloperOptionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(developerOptions: DeveloperOptionsProtocol, elementCallBaseURL: URL) {
        let bindings = DeveloperOptionsScreenViewStateBindings(developerOptions: developerOptions)
        let state = DeveloperOptionsScreenViewState(elementCallBaseURL: elementCallBaseURL, bindings: bindings)
        
        super.init(initialViewState: state)
    }
    
    override func process(viewAction: DeveloperOptionsScreenViewAction) {
        switch viewAction {
        case .clearCache:
            actionsSubject.send(.clearCache)
        }
    }
}
