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
            progressCallback?(mockProgress)
            progressExpectation.fulfill()
            try? await Task.sleep(for: .seconds(10))
            return .success(())
        }
        
        let deferred = deferFulfillment(context.$viewState) { $0.mode == .backupOngoing }
        context.send(viewAction: .logout)
        try await deferred.fulfill()
        
        await fulfillment(of: [progressExpectation])
        XCTAssertEqual(context.viewState.uploadProgress, mockProgress)
    }
    
    func testOfflineState() async throws {
        try await testOngoingState()
        
        let deferred = deferFulfillment(context.$viewState) { $0.mode == .offline }
        reachabilitySubject.send(.unreachable)
        try await deferred.fulfill()
    }
}
