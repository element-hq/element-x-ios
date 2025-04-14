//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class SecureBackupLogoutConfirmationScreenViewModelTests: XCTestCase {
    var viewModel: SecureBackupLogoutConfirmationScreenViewModel!
    var context: SecureBackupLogoutConfirmationScreenViewModel.Context { viewModel.context }
    
    var secureBackupController: SecureBackupControllerMock!
    var reachabilitySubject: CurrentValueSubject<NetworkMonitorReachability, Never>!
    
    override func setUp() {
        secureBackupController = SecureBackupControllerMock()
        secureBackupController.underlyingKeyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(.enabled).asCurrentValuePublisher()
        
        reachabilitySubject = CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable)
        let networkMonitor = NetworkMonitorMock()
        networkMonitor.underlyingReachabilityPublisher = reachabilitySubject.asCurrentValuePublisher()
        
        let appMediator = AppMediatorMock()
        appMediator.underlyingNetworkMonitor = networkMonitor
        
        viewModel = SecureBackupLogoutConfirmationScreenViewModel(secureBackupController: secureBackupController,
                                                                  appMediator: appMediator)
    }
    
    func testInitialState() {
        XCTAssertEqual(context.viewState.mode, .saveRecoveryKey)
    }
    
    func testOngoingState() async throws {
        testInitialState()
        
        let mockProgress = 0.5
        
        let progressExpectation = expectation(description: "The upload progress callback should be called.")
        secureBackupController.waitForKeyBackupUploadProgressCallbackClosure = { progressCallback in
            try? await Task.sleep(for: .seconds(4))
            progressCallback?(mockProgress)
            progressExpectation.fulfill()
            return .success(())
        }
        
        let deferredWaiting = deferFulfillment(context.$viewState) { $0.mode == .waitingToStart(hasStalled: false) }
        context.send(viewAction: .logout)
        try await deferredWaiting.fulfill()
        
        // Wait for the 2-second timeout.
        let deferredHasStalled = deferFulfillment(context.$viewState) { $0.mode == .waitingToStart(hasStalled: true) }
        try await deferredHasStalled.fulfill()
        
        // Wait for the progress to be reported.
        await fulfillment(of: [progressExpectation])
        XCTAssertEqual(context.viewState.mode, .backupOngoing(progress: mockProgress))
    }
    
    func testOfflineState() async throws {
        try await testOngoingState()
        
        let deferred = deferFulfillment(context.$viewState) { $0.mode == .offline }
        reachabilitySubject.send(.unreachable)
        try await deferred.fulfill()
    }
}
