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

@available(iOS 14, *)
typealias SettingsViewModelType = StateStoreViewModel<SettingsViewState,
    SettingsViewAction>
@available(iOS 14, *)
class SettingsViewModel: SettingsViewModelType, SettingsViewModelProtocol {
    // MARK: - Properties

    // MARK: Private

    private let userSession: UserSessionProtocol

    // MARK: Public

    var callback: ((SettingsViewModelAction) -> Void)?

    // MARK: - Setup

    init(withUserSession userSession: UserSessionProtocol) {
        self.userSession = userSession
        let bindings = SettingsViewStateBindings()
        super.init(initialViewState: .init(bindings: bindings, userID: userSession.userID))

        Task {
            if case let .success(userAvatarURLString) = await userSession.clientProxy.loadUserAvatarURLString() {
                if case let .success(avatar) = await userSession.mediaProvider.loadImageFromURLString(userAvatarURLString, size: .user(on: .settings)) {
                    state.userAvatar = avatar
                }
            }
        }

        Task {
            if case let .success(userDisplayName) = await self.userSession.clientProxy.loadUserDisplayName() {
                state.userDisplayName = userDisplayName
            }
        }
    }

    // MARK: - Public

    override func process(viewAction: SettingsViewAction) async {
        switch viewAction {
        case .close:
            callback?(.close)
        case .toggleAnalytics:
            callback?(.toggleAnalytics)
        case .reportBug:
            callback?(.reportBug)
        case .crash:
            callback?(.crash)
        case .logout:
            callback?(.logout)
        }
    }
}
