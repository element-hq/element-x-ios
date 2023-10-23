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

typealias SecureBackupLogoutConfirmationScreenViewModelType = StateStoreViewModel<SecureBackupLogoutConfirmationScreenViewState, SecureBackupLogoutConfirmationScreenViewAction>

class SecureBackupLogoutConfirmationScreenViewModel: SecureBackupLogoutConfirmationScreenViewModelType, SecureBackupLogoutConfirmationScreenViewModelProtocol {
    private let secureBackupController: SecureBackupControllerProtocol
    private let networkMonitor: NetworkMonitorProtocol
    
    @CancellableTask
    private var keyUploadWaitingTask: Task<Void, Never>?
    
    private var actionsSubject: PassthroughSubject<SecureBackupLogoutConfirmationScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<SecureBackupLogoutConfirmationScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(secureBackupController: SecureBackupControllerProtocol, networkMonitor: NetworkMonitorProtocol) {
        self.secureBackupController = secureBackupController
        self.networkMonitor = networkMonitor
        
        super.init(initialViewState: .init(mode: .saveRecoveryKey))
        
        networkMonitor.reachabilityPublisher
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
            state.mode = networkMonitor.reachabilityPublisher.value == .reachable ? .backupOngoing : .offline
            
            keyUploadWaitingTask = Task {
                await secureBackupController.waitForKeyBackup()
                actionsSubject.send(.logout)
            }
        } else {
            actionsSubject.send(.logout)
        }
    }
}
