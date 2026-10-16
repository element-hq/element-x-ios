//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

class UserSession: UserSessionProtocol {
    private var cancellables = Set<AnyCancellable>()
    
    private var authErrorCancellable: AnyCancellable?
    
    let clientProxy: ClientProxyProtocol
    let userSettings: UserSettings
    let userHooks: UserHooks
    
    let mediaProvider: MediaProviderProtocol
    let voiceMessageMediaManager: VoiceMessageMediaManagerProtocol
    let liveLocationService: LiveLocationServiceProtocol
    /// Scans media content, `nil` when no content scanner is configured for the server.
    let contentScannerService: ContentScannerServiceProtocol?
    let notificationService: NotificationServiceProtocol
    
    let callbacks = PassthroughSubject<UserSessionCallback, Never>()
    
    let sessionSecurityStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .unknown, recoveryState: .unknown))
    var sessionSecurityStatePublisher: CurrentValuePublisher<SessionSecurityState, Never> {
        sessionSecurityStateSubject.asCurrentValuePublisher()
    }
    
    init(clientProxy: ClientProxyProtocol,
         userSettings: UserSettings,
         userHooks: UserHooks,
         mediaProvider: MediaProviderProtocol,
         voiceMessageMediaManager: VoiceMessageMediaManagerProtocol,
         liveLocationService: LiveLocationServiceProtocol,
         notificationService: NotificationServiceProtocol) {
        self.clientProxy = clientProxy
        self.userSettings = userSettings
        self.userHooks = userHooks
        
        self.mediaProvider = mediaProvider
        self.voiceMessageMediaManager = voiceMessageMediaManager
        self.liveLocationService = liveLocationService
        self.notificationService = notificationService
        contentScannerService = clientProxy.contentScanner.map(ContentScannerService.init)
        
        authErrorCancellable = clientProxy.actionsPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] callback in
                guard let self else { return }
                switch callback {
                case .receivedAuthError(let isSoftLogout):
                    callbacks.send(.didReceiveAuthError(isSoftLogout: isSoftLogout))
                    authErrorCancellable = nil
                default:
                    break
                }
            }
        
        Publishers.CombineLatest(clientProxy.verificationStatePublisher, clientProxy.secureBackupController.recoveryState)
            .map {
                MXLog.info("Session security state changed, verificationState: \($0), recoveryState: \($1)")
                return SessionSecurityState(verificationState: $0, recoveryState: $1)
            }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.sessionSecurityStateSubject.send(value)
            }
            .store(in: &cancellables)
    }
}
