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
struct SettingsScreenViewModelTests {
    private var clientProxy: ClientProxyMock!
    private var viewModel: SettingsScreenViewModelProtocol!
    private var context: SettingsScreenViewModelType.Context {
        viewModel.context
    }
    
    // MARK: - User status
    
    @Test
    mutating func statusPickerFlow() {
        // Given a screen where no status has been set.
        setupViewModel()
        #expect(!context.viewState.bindings.isPresentingStatusPicker)
        #expect(!context.viewState.bindings.isShowingCustomStatusField)
        #expect(context.viewState.userStatusRowMode == .pick)
        
        // When choosing to pick a status.
        context.send(viewAction: .userStatus(.pickStatus))
        
        // Then the status picker should be presented.
        #expect(context.viewState.bindings.isPresentingStatusPicker)
        #expect(!context.viewState.bindings.isShowingCustomStatusField)
        #expect(context.viewState.userStatusRowMode == .pick)
        
        // When choosing to enter a custom status.
        context.send(viewAction: .userStatus(.customStatus))
        
        // Then the picker should be dismissed and the custom status field shown.
        #expect(!context.viewState.bindings.isPresentingStatusPicker)
        #expect(context.viewState.bindings.isShowingCustomStatusField)
        #expect(context.viewState.userStatusRowMode == .custom)
        
        // When cancelling.
        context.send(viewAction: .userStatus(.cancel))
        
        // Then all status editing should be dismissed.
        #expect(!context.viewState.bindings.isPresentingStatusPicker)
        #expect(!context.viewState.bindings.isShowingCustomStatusField)
        #expect(context.viewState.userStatusRowMode == .pick)
    }
    
    @Test
    mutating func persistingStatus() async throws {
        // Given a screen where no status has been set or removed yet.
        setupViewModel()
        #expect(clientProxy.setUserStatusCallsCount == 0)
        #expect(clientProxy.removeUserStatusCallsCount == 0)
        
        // When setting a status.
        let status = UserStatus.Raw(text: "Away", emoji: "🌴")
        let (setStream, setContinuation) = AsyncStream<UserStatus.Raw>.makeStream()
        clientProxy.setUserStatusClosure = {
            setContinuation.yield($0)
            return .success(())
        }
        let statusSet = deferFulfillment(setStream) { _ in true }
        context.send(viewAction: .userStatus(.set(status)))
        
        // Then only the set endpoint should be called, with the chosen status.
        #expect(try await statusSet.fulfill() == status)
        #expect(clientProxy.setUserStatusCallsCount == 1)
        #expect(clientProxy.removeUserStatusCallsCount == 0)
        
        // When clearing the status.
        let (removeStream, removeContinuation) = AsyncStream<Void>.makeStream()
        clientProxy.removeUserStatusClosure = {
            removeContinuation.yield()
            return .success(())
        }
        let statusRemoved = deferFulfillment(removeStream) { _ in true }
        context.send(viewAction: .userStatus(.set(nil)))
        
        // Then only the remove endpoint should be called, leaving the set call untouched.
        try await statusRemoved.fulfill()
        #expect(clientProxy.removeUserStatusCallsCount == 1)
        #expect(clientProxy.setUserStatusCallsCount == 1)
    }
    
    @Test
    mutating func showsExistingStatus() throws {
        // Given a screen where the user has a status set.
        let status = UserStatus.mockHoliday
        setupViewModel(status: status)
        
        // Then that status should be shown.
        let rawStatus = try #require(status.raw)
        #expect(context.viewState.userStatusRowMode == .show(rawStatus))
    }
    
    @Test
    mutating func reportBug() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .reportBug }
        context.send(viewAction: .reportBug)
        try await deferred.fulfill()
    }
    
    @Test
    mutating func analytics() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .analytics }
        context.send(viewAction: .analytics)
        try await deferred.fulfill()
    }
    
    @Test
    mutating func logout() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .logout }
        context.send(viewAction: .logout)
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private mutating func setupViewModel(status: UserStatus = .init()) {
        clientProxy = ClientProxyMock(.init(userID: "", status: status))
        viewModel = SettingsScreenViewModel(userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                            appSettings: AppSettings.volatile(),
                                            isBugReportServiceEnabled: true,
                                            isInSecondaryWindow: false,
                                            userIndicatorController: UserIndicatorControllerMock())
    }
}
