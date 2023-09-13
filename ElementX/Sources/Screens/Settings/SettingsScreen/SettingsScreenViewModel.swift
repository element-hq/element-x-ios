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
    private let appSettings: AppSettings

    var callback: ((SettingsScreenViewModelAction) -> Void)?
    
    init(userSession: UserSessionProtocol, appSettings: AppSettings) {
        self.userSession = userSession
        self.appSettings = appSettings
        
        var showSessionVerificationSection = false
        if let sessionVerificationController = userSession.sessionVerificationController {
            showSessionVerificationSection = !sessionVerificationController.isVerified
        }
        
        super.init(initialViewState: .init(deviceID: userSession.deviceID,
                                           userID: userSession.userID,
                                           accountProfileURL: userSession.clientProxy.accountURL(action: .profile),
                                           accountSessionsListURL: userSession.clientProxy.accountURL(action: .sessionsList),
                                           showSessionVerificationSection: showSessionVerificationSection,
                                           showDeveloperOptions: appSettings.canShowDeveloperOptions),
                   imageProvider: userSession.mediaProvider)
        
        userSession.clientProxy.avatarURLPublisher
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
                
        Task {
            await userSession.clientProxy.loadUserAvatarURL()
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
    
    override func process(viewAction: SettingsScreenViewAction) {
        switch viewAction {
        case .close:
            callback?(.close)
        case .accountProfile:
            callback?(.accountProfile)
        case .analytics:
            callback?(.analytics)
        case .reportBug:
            callback?(.reportBug)
        case .about:
            callback?(.about)
        case .logout:
            callback?(.logout)
        case .sessionVerification:
            callback?(.sessionVerification)
        case .notifications:
            callback?(.notifications)
        case .accountSessionsList:
            callback?(.accountSessionsList)
        case .advancedSettings:
            callback?(.advancedSettings)
        case .developerOptions:
            callback?(.developerOptions)
            
        case .updateWindow(let window):
            Task {
                guard state.window != window else { return }
                state.window = window
            }
        }
    }
}
