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

typealias TemplateScreenViewModelType = StateStoreViewModel<TemplateScreenViewState, TemplateScreenViewAction>

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
        }
    }
}
