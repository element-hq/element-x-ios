//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias SecureBackupLogoutConfirmationScreenViewModelType = StateStoreViewModel<SecureBackupLogoutConfirmationScreenViewState, SecureBackupLogoutConfirmationScreenViewAction>

class SecureBackupLogoutConfirmationScreenViewModel: SecureBackupLogoutConfirmationScreenViewModelType, SecureBackupLogoutConfirmationScreenViewModelProtocol {
    private let secureBackupController: SecureBackupControllerProtocol
    private let appMediator: AppMediatorProtocol
    
    // periphery:ignore - auto cancels when reassigned
    @CancellableTask
    private var keyUploadWaitingTask: Task<Void, Never>?
    @CancellableTask
    private var keyUploadStalledTask: Task<Void, Error>?
    
    private var actionsSubject: PassthroughSubject<SecureBackupLogoutConfirmationScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupLogoutConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(secureBackupController: SecureBackupControllerProtocol, appMediator: AppMediatorProtocol) {
        self.secureBackupController = secureBackupController
        self.appMediator = appMediator
        
        super.init(initialViewState: .init(mode: .saveRecoveryKey))
        
        appMediator.networkMonitor.reachabilityPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reachability in
                guard let self,
                      state.mode != .saveRecoveryKey else {
                    return
                }
                
                updateMode(with: reachability)
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
        case .settings:
            actionsSubject.send(.settings)
        case .logout:
            attemptLogout()
        }
    }
    
    // MARK: - Private
    
    private func attemptLogout() {
        if case .saveRecoveryKey = state.mode {
            updateMode(with: appMediator.networkMonitor.reachabilityPublisher.value)
            
            keyUploadWaitingTask = Task {
                var result = await waitForKeyBackupUpload()
                
                if case .failure = result {
                    // Retry the upload first, conditions might have changed.
                    result = await waitForKeyBackupUpload()
                }
                
                guard case .success = result else {
                    MXLog.error("Aborting logout due to failure waiting for backup upload.")
                    state.bindings.alertInfo = .init(id: .backupUploadFailed)
                    return
                }
                
                guard !Task.isCancelled else { return }
                
                actionsSubject.send(.logout)
            }
        } else {
            actionsSubject.send(.logout)
        }
    }
    
    private func waitForKeyBackupUpload() async -> Result<Void, SecureBackupControllerError> {
        await secureBackupController.waitForKeyBackupUpload { [weak self] progress in
            self?.state.mode = .backupOngoing(progress: progress)
        }
    }
    
    private func updateMode(with reachability: NetworkMonitorReachability) {
        if reachability == .reachable {
            state.mode = .waitingToStart(hasStalled: false)
            monitorUploadProgress()
        } else {
            state.mode = .offline
        }
    }
    
    private func monitorUploadProgress() {
        keyUploadStalledTask = Task { [weak self] in
            try await Task.sleep(for: .seconds(2))
            guard let self, case .waitingToStart(hasStalled: false) = state.mode else { return }
            state.mode = .waitingToStart(hasStalled: true)
        }
    }
}
