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
    private var actionsSubject: PassthroughSubject<SettingsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<SettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol, appSettings: AppSettings) {
        super.init(initialViewState: .init(deviceID: userSession.deviceID,
                                           userID: userSession.userID,
                                           accountProfileURL: userSession.clientProxy.accountURL(action: .profile),
                                           accountSessionsListURL: userSession.clientProxy.accountURL(action: .sessionsList),
                                           showDeveloperOptions: appSettings.isDevelopmentBuild),
                   imageProvider: userSession.mediaProvider)
        
        userSession.clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.userDisplayNamePublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userDisplayName, on: self)
            .store(in: &cancellables)
        
        userSession.sessionSecurityStatePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] securityState in
                guard let self else { return }
                
                switch (securityState.verificationState, securityState.recoveryState) {
                case (.unverified, _):
                    state.showSecuritySectionBadge = true
                    state.securitySectionMode = .sessionVerification
                case (.unverifiedLastSession, .incomplete):
                    state.showSecuritySectionBadge = true
                    state.securitySectionMode = .sessionVerification
                case (.verified, .disabled):
                    state.showSecuritySectionBadge = true
                    state.securitySectionMode = .secureBackup
                case (.verified, .incomplete):
                    state.showSecuritySectionBadge = true
                    state.securitySectionMode = .secureBackup
                case (.unknown, _):
                    state.showSecuritySectionBadge = false
                    state.securitySectionMode = .none
                default:
                    state.showSecuritySectionBadge = false
                    state.securitySectionMode = .secureBackup
                }
            }
            .store(in: &cancellables)
        
        Task {
            await userSession.clientProxy.loadUserAvatarURL()
            await userSession.clientProxy.loadUserDisplayName()
        }
    }
    
    override func process(viewAction: SettingsScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .userDetails:
            actionsSubject.send(.userDetails)
        case .accountProfile:
            actionsSubject.send(.accountProfile)
        case .analytics:
            actionsSubject.send(.analytics)
        case .appLock:
            actionsSubject.send(.appLock)
        case .reportBug:
            actionsSubject.send(.reportBug)
        case .about:
            actionsSubject.send(.about)
        case .logout:
            actionsSubject.send(.logout)
        case .sessionVerification:
            actionsSubject.send(.sessionVerification)
        case .secureBackup:
            actionsSubject.send(.secureBackup)
        case .notifications:
            actionsSubject.send(.notifications)
        case .accountSessionsList:
            actionsSubject.send(.accountSessionsList)
        case .advancedSettings:
            actionsSubject.send(.advancedSettings)
        case .developerOptions:
            actionsSubject.send(.developerOptions)
        }
    }
}
