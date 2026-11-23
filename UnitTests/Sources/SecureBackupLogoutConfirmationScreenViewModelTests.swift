//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
struct SecureBackupLogoutConfirmationScreenViewModelTests {
    private var viewModel: SecureBackupLogoutConfirmationScreenViewModel
    private var context: SecureBackupLogoutConfirmationScreenViewModel.Context {
        viewModel.context
    }
    
    private var clientProxy: ClientProxyMock
    private var secureBackupController: SecureBackupControllerMock
    private var reachabilitySubject: CurrentValueSubject<HomeserverReachability, Never>
    
    init() {
        secureBackupController = SecureBackupControllerMock()
        
        reachabilitySubject = CurrentValueSubject<HomeserverReachability, Never>(.reachable)
        
        clientProxy = ClientProxyMock(.init())
        clientProxy.secureBackupController = secureBackupController
        clientProxy.homeserverReachabilityPublisher = reachabilitySubject.asCurrentValuePublisher()
        
        viewModel = SecureBackupLogoutConfirmationScreenViewModel(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                                  mode: .saveRecoveryKey)
    }
    
    @Test("The screen starts in the mode it was created with, showing the user's profile")
    func initialState() {
        #expect(context.viewState.mode == .saveRecoveryKey)
        #expect(context.viewState.userProfile == clientProxy.userProfilePublisher.value)
    }
    
    @Test("The screen starts in the right mode based on the user's recovery options",
          arguments: [(true, SecureBackupRecoveryState.enabled, SecureBackupLogoutConfirmationScreenViewMode.confirmationOnly),
                      (true, .disabled, .confirmationOnly),
                      (false, .enabled, .saveRecoveryKey),
                      (false, .incomplete, .noRecovery),
                      (false, .disabled, .noRecovery)])
    func modeFromRecoveryOptions(hasOtherVerifiedDevice: Bool,
                                 recoveryState: SecureBackupRecoveryState,
                                 expectedMode: SecureBackupLogoutConfirmationScreenViewMode) {
        let mode = SecureBackupLogoutConfirmationScreenViewMode(hasOtherVerifiedDevice: hasOtherVerifiedDevice,
                                                                recoveryState: recoveryState)
        #expect(mode == expectedMode)
    }
    
    @Test("Logging out with a recovery key shows the backup progress once it has stalled")
    func ongoingState() async throws {
        #expect(context.viewState.mode == .saveRecoveryKey)
        
        try await confirmation { confirmation in
            secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { stateSubject in
                try? await Task.sleep(for: .seconds(4))
                stateSubject.send(.uploading(uploadedKeyCount: 50, totalKeyCount: 100))
                confirmation()
                return .success(())
            }
            
            let deferredWaiting = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: false) }
            context.send(viewAction: .logout)
            _ = try await deferredWaiting.fulfill()
            
            // Wait for the 2-second timeout.
            let deferredHasStalled = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: true) }
            _ = try await deferredHasStalled.fulfill()
            
            try await deferFulfillment(context.observe(\.viewState.mode)) { $0 == .backupOngoing(progress: 0.5) }.fulfill()
        }
    }
    
    @Test("Losing the connection during the backup switches to the offline mode")
    func offlineState() async throws {
        #expect(context.viewState.mode == .saveRecoveryKey)
        
        try await confirmation { confirmation in
            secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { stateSubject in
                try? await Task.sleep(for: .seconds(4))
                stateSubject.send(.uploading(uploadedKeyCount: 50, totalKeyCount: 100))
                confirmation()
                return .success(())
            }
            
            let deferredWaiting = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: false) }
            context.send(viewAction: .logout)
            try await deferredWaiting.fulfill()
            
            // Wait for the 2-second timeout.
            let deferredHasStalled = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .waitingToStart(hasStalled: true) }
            try await deferredHasStalled.fulfill()
            
            try await deferFulfillment(context.observe(\.viewState.mode)) { $0 == .backupOngoing(progress: 0.5) }.fulfill()
        }
        
        let deferred = deferFulfillment(context.observe(\.viewState.mode)) { $0 == .offline }
        reachabilitySubject.send(.unreachable)
        try await deferred.fulfill()
    }
    
    @Test("Removing the device logs out straight away when there are no keys to back up",
          arguments: [SecureBackupLogoutConfirmationScreenViewMode.confirmationOnly, .noRecovery])
    func logoutWithNothingToBackUp(mode: SecureBackupLogoutConfirmationScreenViewMode) async throws {
        let viewModel = SecureBackupLogoutConfirmationScreenViewModel(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                                      mode: mode)
        #expect(viewModel.context.viewState.mode == mode)
        
        let deferred = deferFulfillment(viewModel.actions) { $0.isLogout }
        viewModel.context.send(viewAction: .logout)
        try await deferred.fulfill()
        
        // There are no keys to wait for, and the question stays as it is.
        #expect(viewModel.context.viewState.mode == mode)
        #expect(secureBackupController.waitForKeyBackupUploadUploadStateSubjectCallsCount == 0)
    }
    
    @Test("Cancelling is forwarded to the coordinator")
    func cancel() async throws {
        let deferred = deferFulfillment(viewModel.actions) { $0.isCancel }
        context.send(viewAction: .cancel)
        try await deferred.fulfill()
    }
    
    @Test("Generating a recovery key is forwarded to the coordinator")
    func generateRecoveryKey() async throws {
        let deferred = deferFulfillment(viewModel.actions) { $0.isGenerateRecoveryKey }
        context.send(viewAction: .generateRecoveryKey)
        try await deferred.fulfill()
    }
    
    @Test("Checking the recovery key is forwarded to the coordinator")
    func checkRecoveryKey() async throws {
        let deferred = deferFulfillment(viewModel.actions) { $0.isCheckRecoveryKey }
        context.send(viewAction: .checkRecoveryKey)
        try await deferred.fulfill()
    }
    
    @Test("Continuing with a new recovery key waits for the backup before logging out")
    func logoutAfterNewRecoveryKey() async throws {
        let viewModel = SecureBackupLogoutConfirmationScreenViewModel(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                                      mode: .noRecovery)
        secureBackupController.waitForKeyBackupUploadUploadStateSubjectClosure = { _ in .success(()) }
        
        let deferredLogout = deferFulfillment(viewModel.actions) { $0.isLogout }
        let deferredContinuation = deferFulfillment(viewModel.actions) { action in
            if case let .generateRecoveryKey(continuation) = action {
                continuation.yield()
                return true
            }
            return false
        }
        viewModel.context.send(viewAction: .generateRecoveryKey)
        try await deferredContinuation.fulfill()
        try await deferredLogout.fulfill()
        
        // Unlike removing the device without a recovery key, the new keys have to be uploaded.
        #expect(secureBackupController.waitForKeyBackupUploadUploadStateSubjectCallsCount == 1)
    }
}

private extension SecureBackupLogoutConfirmationScreenViewModelAction {
    var isCancel: Bool {
        switch self {
        case .cancel: true
        default: false
        }
    }
    
    var isCheckRecoveryKey: Bool {
        switch self {
        case .checkRecoveryKey: true
        default: false
        }
    }
    
    var isGenerateRecoveryKey: Bool {
        switch self {
        case .generateRecoveryKey: true
        default: false
        }
    }
    
    var isLogout: Bool {
        switch self {
        case .logout: true
        default: false
        }
    }
}
