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
    
    /// Whether the SDK's verification state can be relied upon yet, see ``settleVerificationState(clock:)``.
    private let isVerificationStateSettledSubject = CurrentValueSubject<Bool, Never>(false)
    @CancellableTask private var verificationStateTimeoutTask: Task<Void, Never>?
    
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
         notificationService: NotificationServiceProtocol,
         clock: any Clock<Duration> = ContinuousClock()) {
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
        
        Publishers.CombineLatest3(clientProxy.verificationStatePublisher, clientProxy.secureBackupController.recoveryState, isVerificationStateSettledSubject)
            .map { verificationState, recoveryState, isVerificationStateSettled in
                let publishedVerificationState = isVerificationStateSettled || verificationState == .verified ? verificationState : .unknown
                MXLog.info("Session security state changed, verificationState: \(publishedVerificationState) (SDK: \(verificationState)), recoveryState: \(recoveryState)")
                return SessionSecurityState(verificationState: publishedVerificationState, recoveryState: recoveryState)
            }
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.sessionSecurityStateSubject.send(value)
            }
            .store(in: &cancellables)
        
        settleVerificationState(clock: clock)
    }
    
    func waitForSettledVerificationState() async {
        for await isSettled in isVerificationStateSettledSubject.values where isSettled {
            return
        }
    }
    
    // MARK: - Private
    
    /// The SDK reports this session as unverified until it has set up encryption, and a new account's session
    /// until a sync brings back the keys it was just signed with. Anything but verified is held back until then
    /// (for 10 seconds at most), so that onboarding doesn't briefly ask to verify a session that is verified.
    private func settleVerificationState(clock: any Clock<Duration>) {
        clientProxy.verificationStatePublisher
            .first { $0 == .verified }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.markVerificationStateAsSettled()
            }
            .store(in: &cancellables)
        
        verificationStateTimeoutTask = Task { [weak self] in
            try? await clock.sleep(for: .seconds(10))
            guard let self, !Task.isCancelled else { return }
            MXLog.warning("Timed out waiting for the verification state to settle.")
            markVerificationStateAsSettled()
        }
        
        let clientProxy = clientProxy
        Task { [weak self] in
            await clientProxy.waitForE2EEInitializationTasks()
            
            // A new identity is trusted straight away, so it is about to verify this session.
            if clientProxy.verificationStatePublisher.value == .unverified,
               case .success(let identity) = await clientProxy.userIdentity(for: clientProxy.userID, fallBackToServer: false),
               identity?.verificationState == .verified {
                MXLog.info("Waiting for a sync to verify this session with its new identity.")
                return
            }
            
            self?.markVerificationStateAsSettled()
        }
    }
    
    private func markVerificationStateAsSettled() {
        guard !isVerificationStateSettledSubject.value else { return }
        verificationStateTimeoutTask = nil
        isVerificationStateSettledSubject.send(true)
    }
}
