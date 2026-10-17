//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SecureBackupLogoutConfirmationScreenViewModelType = StateStoreViewModelV2<SecureBackupLogoutConfirmationScreenViewState, SecureBackupLogoutConfirmationScreenViewAction>

class SecureBackupLogoutConfirmationScreenViewModel: SecureBackupLogoutConfirmationScreenViewModelType, SecureBackupLogoutConfirmationScreenViewModelProtocol {
    private let secureBackupController: SecureBackupControllerProtocol
    private let homeserverReachabilityPublisher: CurrentValuePublisher<HomeserverReachability, Never>
    
    private let backupUploadStateSubject: CurrentValueSubject<SecureBackupSteadyState, Never> = .init(.waiting)
    
    @CancellableTask
    private var keyUploadWaitingTask: Task<Void, Never>?
    @CancellableTask
    private var keyUploadStalledTask: Task<Void, Error>?
    @CancellableTask
    private var recoveryKeyTask: Task<Void, Never>?
    
    private var actionsSubject: PassthroughSubject<SecureBackupLogoutConfirmationScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupLogoutConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(secureBackupController: SecureBackupControllerProtocol,
         homeserverReachabilityPublisher: CurrentValuePublisher<HomeserverReachability, Never>,
         learnMoreURL: URL,
         mode: SecureBackupLogoutConfirmationScreenViewMode = .saveRecoveryKey) {
        self.secureBackupController = secureBackupController
        self.homeserverReachabilityPublisher = homeserverReachabilityPublisher
        
        super.init(initialViewState: .init(learnMoreURL: learnMoreURL, mode: mode))
        
        backupUploadStateSubject.combineLatest(homeserverReachabilityPublisher)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] backupState, reachability in
                guard let self, !state.mode.isInitial else { return }
                updateMode(backupState: backupState, reachability: reachability)
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: SecureBackupLogoutConfirmationScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .cancel:
            keyUploadWaitingTask = nil
            actionsSubject.send(.cancel)
        case .checkRecoveryKey:
            requestRecoveryKey { .checkRecoveryKey($0) }
        case .generateRecoveryKey:
            requestRecoveryKey { .generateRecoveryKey($0) }
        case .logout:
            attemptLogout()
        }
    }
    
    // MARK: - Private
    
    /// Asks for the user to be taken through a recovery key screen, and carries on removing the device once they have finished it.
    private func requestRecoveryKey(action: (SecureBackupLogoutConfirmationScreenRecoveryKeyContinuation) -> SecureBackupLogoutConfirmationScreenViewModelAction) {
        let (stream, continuation) = AsyncStream<Void>.makeStream()
        actionsSubject.send(action(continuation))
        
        recoveryKeyTask = Task { [weak self] in
            for await _ in stream {
                // The keys now have to be backed up before the device can go.
                self?.state.mode = .saveRecoveryKey
                self?.attemptLogout()
            }
        }
    }
    
    private func attemptLogout() {
        if case .saveRecoveryKey = state.mode {
            updateMode(backupState: backupUploadStateSubject.value, reachability: homeserverReachabilityPublisher.value)
            
            keyUploadWaitingTask = Task {
                var result = await secureBackupController.waitForKeyBackupUpload(uploadStateSubject: backupUploadStateSubject)
                
                guard !Task.isCancelled else { return }
                
                if case .failure = result {
                    // Retry the upload first, conditions might have changed.
                    result = await secureBackupController.waitForKeyBackupUpload(uploadStateSubject: backupUploadStateSubject)
                }
                
                guard !Task.isCancelled else { return }
                
                guard case .success = result else {
                    MXLog.error("Aborting logout due to failure waiting for backup upload.")
                    state.bindings.alertInfo = .init(id: .backupUploadFailed)
                    return
                }
                
                actionsSubject.send(.logout)
            }
        } else {
            actionsSubject.send(.logout)
        }
    }
    
    private func updateMode(backupState: SecureBackupSteadyState, reachability: HomeserverReachability) {
        switch (backupState, reachability) {
        case (.waiting, .reachable):
            state.mode = .waitingToStart(hasStalled: false)
            showAsStalledAfterTimeout()
        case (.uploading(let uploadedKeyCount, let totalKeyCount), .reachable):
            state.mode = .backupOngoing(progress: Double(uploadedKeyCount) / Double(totalKeyCount))
        case (.error, .reachable):
            break // Nothing to do here, it will be handled with the result.
        case (.done, .reachable):
            state.mode = .backupOngoing(progress: 1.0)
        case (_, .unreachable), (_, .suspended):
            state.mode = .offline
        }
    }
    
    /// If we stay in the waiting state for more than 2-seconds we ask the user to check their connection.
    private func showAsStalledAfterTimeout() {
        keyUploadStalledTask = Task { [weak self] in
            try await Task.sleep(for: .seconds(2))
            guard let self, case .waitingToStart(hasStalled: false) = state.mode else { return }
            state.mode = .waitingToStart(hasStalled: true)
        }
    }
}
