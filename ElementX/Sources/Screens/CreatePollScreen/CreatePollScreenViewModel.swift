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

typealias CreatePollScreenViewModelType = StateStoreViewModel<CreatePollScreenViewState, CreatePollScreenViewAction>

class CreatePollScreenViewModel: CreatePollScreenViewModelType, CreatePollScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<CreatePollScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<CreatePollScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(initialViewState: .init())
    }
    
    // MARK: - Public
    
    override func process(viewAction: CreatePollScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .create:
            actionsSubject.send(.create)
        case .cancel:
            actionsSubject.send(.cancel)
        }
    }
}
