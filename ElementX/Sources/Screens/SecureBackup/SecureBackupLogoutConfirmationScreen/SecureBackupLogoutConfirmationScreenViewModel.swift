//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
                
                if reachability == .reachable {
                    state.mode = .backupOngoing
                } else {
                    state.mode = .offline
                }
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
        if state.mode == .saveRecoveryKey {
            state.mode = appMediator.networkMonitor.reachabilityPublisher.value == .reachable ? .backupOngoing : .offline
            
            keyUploadWaitingTask = Task {
                var result = await secureBackupController.waitForKeyBackupUpload()
                
                if case .failure = result {
                    // Retry the upload first, conditions might have changed.
                    result = await secureBackupController.waitForKeyBackupUpload()
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
}
