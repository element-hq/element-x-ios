//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SettingsScreenViewModelType = StateStoreViewModelV2<SettingsScreenViewState, SettingsScreenViewAction>

class SettingsScreenViewModel: SettingsScreenViewModelType, SettingsScreenViewModelProtocol {
    private let appSettings: AppSettings
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<SettingsScreenViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<SettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol, appSettings: AppSettings, isBugReportServiceEnabled: Bool, isInSecondaryWindow: Bool, userIndicatorController: UserIndicatorControllerProtocol) {
        self.appSettings = appSettings
        clientProxy = userSession.clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(deviceID: userSession.clientProxy.deviceID,
                                           userProfile: userSession.clientProxy.userProfilePublisher.value,
                                           showLinkNewDeviceButton: appSettings.linkNewDeviceEnabled,
                                           showAccountDeactivation: userSession.clientProxy.canDeactivateAccount,
                                           showDeveloperOptions: appSettings.developerOptionsEnabled,
                                           showAnalyticsSettings: appSettings.canPromptForAnalytics,
                                           isBugReportServiceEnabled: isBugReportServiceEnabled,
                                           navigationBarVisibility: isInSecondaryWindow ? .hidden : .automatic),
                   mediaProvider: userSession.mediaProvider)
        
        appSettings.developerOptionsEnabledPublisher
            .weakAssign(to: \.state.showDeveloperOptions, on: self)
            .store(in: &cancellables)
        
        appSettings.linkNewDeviceEnabledPublisher
            .weakAssign(to: \.state.showLinkNewDeviceButton, on: self)
            .store(in: &cancellables)
        
        userSession.clientProxy.userProfilePublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userProfile, on: self)
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
            if appSettings.userStatusEnabled, case .success(true) = await userSession.clientProxy.isUserStatusSupported() {
                state.showUserStatus = true
            }
            await userSession.clientProxy.loadUserProfileIfNeeded()
        }
        Task { await state.accountProfileURL = userSession.clientProxy.accountURL(action: .profile) }
    }
    
    override func process(viewAction: SettingsScreenViewAction) {
        switch viewAction {
        case .close:
            actionsSubject.send(.close)
        case .userDetails:
            actionsSubject.send(.userDetails)
        case .userStatus(.pickStatus):
            state.bindings.isPresentingStatusPicker = true
        case .userStatus(.customStatus):
            state.bindings.isPresentingStatusPicker = false
            state.bindings.isShowingCustomStatusField = true
        case .userStatus(.pickCustomEmoji):
            pickCustomEmoji()
        case .userStatus(.set(let status)):
            Task { await setUserStatus(status) }
        case .userStatus(.cancel):
            state.bindings.isPresentingStatusPicker = false
            state.bindings.isShowingCustomStatusField = false
        case .linkNewDevice:
            actionsSubject.send(.linkNewDevice)
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
        case .labs:
            actionsSubject.send(.labs)
        case .enableDeveloperOptions:
            appSettings.developerOptionsEnabled.toggle()
        case .developerOptions:
            actionsSubject.send(.developerOptions)
        case .deactivateAccount:
            actionsSubject.send(.deactivateAccount)
        }
    }
    
    // MARK: - Private
    
    private var pickCustomEmojiCancellable: AnyCancellable?
    private func pickCustomEmoji() {
        let (stream, continuation) = AsyncStream<String>.makeStream()
        actionsSubject.send(.userStatusEmojiPicker(continuation))
        
        pickCustomEmojiCancellable = Task { [weak self] in
            for await emoji in stream {
                self?.state.bindings.customStatusEmoji = Character(emoji)
            }
        }
        .asCancellable()
    }
    
    func setUserStatus(_ status: UserStatus.Raw?) async {
        // Loading state tbc
        state.bindings.isPresentingStatusPicker = false
        state.bindings.isShowingCustomStatusField = false
        
        let result = if let status {
            await clientProxy.setUserStatus(status)
        } else {
            await clientProxy.removeUserStatus()
        }
        
        switch result {
        case .success:
            break // Loading/error state tbc
        case .failure:
            userIndicatorController.submitIndicator(.init(id: UUID().uuidString,
                                                          type: .toast,
                                                          title: L10n.errorUnknown,
                                                          icon: \.close))
        }
    }
}
