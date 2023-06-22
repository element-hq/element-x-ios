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
    
    private let appSettings: AppSettings
    
    init() {
        appSettings = ServiceLocator.shared.settings
        let bindings = DeveloperOptionsScreenViewStateBindings(shouldCollapseRoomStateEvents: appSettings.shouldCollapseRoomStateEvents,
                                                               userSuggestionsEnabled: appSettings.userSuggestionsEnabled,
                                                               readReceiptsEnabled: appSettings.readReceiptsEnabled,
                                                               isEncryptionSyncEnabled: appSettings.isEncryptionSyncEnabled)
        let state = DeveloperOptionsScreenViewState(bindings: bindings)
        
        super.init(initialViewState: state)
        
        appSettings.$shouldCollapseRoomStateEvents
            .weakAssign(to: \.state.bindings.shouldCollapseRoomStateEvents, on: self)
            .store(in: &cancellables)
    }
    
    override func process(viewAction: DeveloperOptionsScreenViewAction) {
        switch viewAction {
        case .changedShouldCollapseRoomStateEvents:
            appSettings.shouldCollapseRoomStateEvents = state.bindings.shouldCollapseRoomStateEvents
        case .changedUserSuggestionsEnabled:
            appSettings.userSuggestionsEnabled = state.bindings.userSuggestionsEnabled
        case .changedReadReceiptsEnabled:
            appSettings.readReceiptsEnabled = state.bindings.readReceiptsEnabled
        case .changedIsEncryptionSyncEnabled:
            appSettings.isEncryptionSyncEnabled = state.bindings.isEncryptionSyncEnabled
        case .clearCache:
            callback?(.clearCache)
        }
    }
}
