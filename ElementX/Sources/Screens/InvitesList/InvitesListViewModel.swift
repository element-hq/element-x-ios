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

typealias InvitesListViewModelType = StateStoreViewModel<InvitesListViewState, InvitesListViewAction>

class InvitesListViewModel: InvitesListViewModelType, InvitesListViewModelProtocol {
    private var actionsSubject: PassthroughSubject<InvitesListViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<InvitesListViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(promptType: InvitesListPromptType, initialCount: Int = 0) {
        super.init(initialViewState: InvitesListViewState(promptType: promptType, count: 0))
    }
    
    // MARK: - Public
    
    override func process(viewAction: InvitesListViewAction) {
        switch viewAction {
        case .accept:
            actionsSubject.send(.accept)
        case .cancel:
            actionsSubject.send(.cancel)
        case .incrementCount:
            state.count += 1
        case .decrementCount:
            state.count -= 1
        }
    }
}
