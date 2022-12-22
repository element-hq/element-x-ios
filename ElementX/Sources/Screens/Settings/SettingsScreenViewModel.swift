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

typealias SettingsScreenViewModelType = StateStoreViewModel<SettingsScreenViewState, SettingsScreenViewAction>

class SettingsScreenViewModel: SettingsScreenViewModelType, SettingsScreenViewModelProtocol {
    private let userSession: UserSessionProtocol

    var callback: ((SettingsScreenViewModelAction) -> Void)?

    init(withUserSession userSession: UserSessionProtocol) {
        self.userSession = userSession
        let bindings = SettingsScreenViewStateBindings(timelineStyle: ServiceLocator.shared.settings.timelineStyle)
        super.init(initialViewState: .init(bindings: bindings,
                                           deviceID: userSession.deviceId,
                                           userID: userSession.userID,
                                           showSessionVerificationSection: !(userSession.sessionVerificationController?.isVerified ?? false)),
                   imageProvider: userSession.mediaProvider)
        
        listenToSettingsChange(publisher: ServiceLocator.shared.settings.$timelineStyle, keyPath: \.timelineStyle)
        
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
        
        userSession.callbacks
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                switch callback {
                case .sessionVerificationNeeded:
                    self?.state.showSessionVerificationSection = true
                case .didVerifySession:
                    self?.state.showSessionVerificationSection = false
                default:
                    break
                }
            }
            .store(in: &cancellables)
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
        case .sessionVerification:
            callback?(.sessionVerification)
        case .changedTimelineStyle:
            ServiceLocator.shared.settings.timelineStyle = state.bindings.timelineStyle
        }
    }
    
    private func listenToSettingsChange<Value>(publisher: AnyPublisher<Value, Never>,
                                               keyPath: WritableKeyPath<SettingsScreenViewStateBindings, Value>) where Value: Equatable {
        publisher.sink { [weak self] newValue in
            guard newValue != self?.state.bindings[keyPath: keyPath] else {
                return
            }
            
            self?.state.bindings[keyPath: keyPath] = newValue
        }
        .store(in: &cancellables)
    }
}
