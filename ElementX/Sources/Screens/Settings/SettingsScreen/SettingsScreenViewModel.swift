//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias SettingsScreenViewModelType = StateStoreViewModel<SettingsScreenViewState, SettingsScreenViewAction>

class SettingsScreenViewModel: SettingsScreenViewModelType, SettingsScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<SettingsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<SettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol) {
        super.init(initialViewState: .init(deviceID: userSession.clientProxy.deviceID,
                                           userID: userSession.clientProxy.userID,
                                           showAccountDeactivation: userSession.clientProxy.canDeactivateAccount,
                                           showDeveloperOptions: AppSettings.isDevelopmentBuild),
                   mediaProvider: userSession.mediaProvider)
        
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
        
        userSession.clientProxy.ignoredUsersPublisher
            .receive(on: DispatchQueue.main)
            .map {
                guard let blockedUsers = $0 else {
                    return false
                }
                
                return !blockedUsers.isEmpty
            }
            .weakAssign(to: \.state.showBlockedUsers, on: self)
            .store(in: &cancellables)
        
        Task {
            await userSession.clientProxy.loadUserAvatarURL()
            await userSession.clientProxy.loadUserDisplayName()
            await state.accountProfileURL = userSession.clientProxy.accountURL(action: .profile)
            await state.accountSessionsListURL = userSession.clientProxy.accountURL(action: .sessionsList)
        }
    }
    
    override func process(viewAction: SettingsScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .userDetails:
            actionsSubject.send(.userDetails)
        case let .manageAccount(url):
            actionsSubject.send(.manageAccount(url: url))
        case .analytics:
            actionsSubject.send(.analytics)
        case .appLock:
            actionsSubject.send(.appLock)
        case .reportBug:
            actionsSubject.send(.reportBug)
        case .about:
            actionsSubject.send(.about)
        case .blockedUsers:
            actionsSubject.send(.blockedUsers)
        case .logout:
            actionsSubject.send(.logout)
        case .secureBackup:
            actionsSubject.send(.secureBackup)
        case .notifications:
            actionsSubject.send(.notifications)
        case .advancedSettings:
            actionsSubject.send(.advancedSettings)
        case .enableDeveloperOptions:
            state.showDeveloperOptions = true
        case .developerOptions:
            actionsSubject.send(.developerOptions)
        case .deactivateAccount:
            actionsSubject.send(.deactivateAccount)
        }
    }
}
