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

typealias SettingsScreenViewModelType = StateStoreViewModel<SettingsScreenViewState, SettingsScreenViewAction>

class SettingsScreenViewModel: SettingsScreenViewModelType, SettingsScreenViewModelProtocol {
    private let userSession: UserSessionProtocol

    var callback: ((SettingsScreenViewModelAction) -> Void)?

    init(withUserSession userSession: UserSessionProtocol) {
        self.userSession = userSession
        let bindings = SettingsScreenViewStateBindings()
        super.init(initialViewState: .init(bindings: bindings, deviceID: userSession.deviceId, userID: userSession.userID),
                   imageProvider: userSession.mediaProvider)
        
        Task {
            if case let .success(userAvatarURL) = await userSession.clientProxy.loadUserAvatarURL() {
                state.userAvatarURL = userAvatarURL
            }
        }
        
        Task {
            if case let .success(userDisplayName) = await self.userSession.clientProxy.loadUserDisplayName() {
                state.userDisplayName = userDisplayName
            }
        }
    }
    
    override func process(viewAction: SettingsScreenViewAction) async {
        switch viewAction {
        case .close:
            callback?(.close)
        case .toggleAnalytics:
            callback?(.toggleAnalytics)
        case .reportBug:
            callback?(.reportBug)
        case .logout:
            callback?(.logout)
        }
    }
}
