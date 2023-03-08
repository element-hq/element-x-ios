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

import SwiftUI

typealias DeveloperOptionsScreenViewModelType = StateStoreViewModel<DeveloperOptionsScreenViewState, DeveloperOptionsScreenViewAction>

class DeveloperOptionsScreenViewModel: DeveloperOptionsScreenViewModelType, DeveloperOptionsScreenViewModelProtocol {
    var callback: ((DeveloperOptionsScreenViewModelAction) -> Void)?
    
    init() {
        super.init(initialViewState: DeveloperOptionsScreenViewState(bindings: DeveloperOptionsScreenViewStateBindings(shouldCollapseRoomStateEvents: ServiceLocator.shared.settings.shouldCollapseRoomStateEvents, showStartChatFlow: ServiceLocator.shared.settings.startChatFlowFeatureFlag)))
        
        ServiceLocator.shared.settings.$shouldCollapseRoomStateEvents
            .weakAssign(to: \.state.bindings.shouldCollapseRoomStateEvents, on: self)
            .store(in: &cancellables)
    }
    
    override func process(viewAction: DeveloperOptionsScreenViewAction) async {
        switch viewAction {
        case .changedShouldCollapseRoomStateEvents:
            ServiceLocator.shared.settings.shouldCollapseRoomStateEvents = state.bindings.shouldCollapseRoomStateEvents
        case .changedShowStartChatFlow:
            ServiceLocator.shared.settings.startChatFlowFeatureFlag = state.bindings.showStartChatFlow
        }
    }
}
