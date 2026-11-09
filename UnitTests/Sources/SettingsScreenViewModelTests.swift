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
    
    @Test("Picking a status, entering a custom one and cancelling update the status row")
    mutating func statusPickerFlow() {
        // Given a screen where no status has been set.
        setupViewModel()
        #expect(!context.viewState.bindings.isPresentingStatusPicker)
        #expect(!context.viewState.bindings.isShowingCustomStatusField)
        #expect(context.viewState.userStatusRowMode == .pickStatusButton)
        
        // When choosing to pick a status.
        context.send(viewAction: .userStatus(.pickStatus))
        
        // Then the status picker should be presented.
        #expect(context.viewState.bindings.isPresentingStatusPicker)
        #expect(!context.viewState.bindings.isShowingCustomStatusField)
        #expect(context.viewState.userStatusRowMode == .pickStatusButton)
        
        // When choosing to enter a custom status.
        context.send(viewAction: .userStatus(.customStatus))
        
        // Then the picker should be dismissed and the custom status field shown.
        #expect(!context.viewState.bindings.isPresentingStatusPicker)
        #expect(context.viewState.bindings.isShowingCustomStatusField)
        #expect(context.viewState.userStatusRowMode == .customStatusInput(emoji: "😄"))
        
        // When cancelling.
        context.send(viewAction: .userStatus(.cancel))
        
        // Then all status editing should be dismissed.
        #expect(!context.viewState.bindings.isPresentingStatusPicker)
        #expect(!context.viewState.bindings.isShowingCustomStatusField)
        #expect(context.viewState.userStatusRowMode == .pickStatusButton)
    }
    
    @Test("Setting and clearing a status call the matching endpoints")
    mutating func persistingStatus() async throws {
        // Given a screen where no status has been set or removed yet.
        setupViewModel()
        #expect(clientProxy.setUserStatusCallsCount == 0)
        #expect(clientProxy.clearUserStatusCallsCount == 0)
        
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
        #expect(clientProxy.clearUserStatusCallsCount == 0)
        
        // When clearing the status.
        let (removeStream, removeContinuation) = AsyncStream<Void>.makeStream()
        clientProxy.clearUserStatusClosure = {
            removeContinuation.yield()
            return .success(())
        }
        let statusRemoved = deferFulfillment(removeStream) { _ in true }
        context.send(viewAction: .userStatus(.clear))
        
        // Then the clear user status endpoint should be called.
        try await statusRemoved.fulfill()
        #expect(clientProxy.clearUserStatusCallsCount == 1)
        #expect(clientProxy.setUserStatusCallsCount == 1)
    }
    
    @Test("Clearing a call status calls only the clear endpoint")
    mutating func clearCallStatus() async throws {
        // Given a screen where the user has a call status set.
        let callStatus = UserStatus.mockCall
        setupViewModel(status: callStatus)
        #expect(!clientProxy.clearUserStatusCalled)
        #expect(!clientProxy.setUserStatusCalled)
        
        // When clearing the status.
        let (removeStream, removeContinuation) = AsyncStream<Void>.makeStream()
        clientProxy.clearUserStatusClosure = {
            removeContinuation.yield()
            return .success(())
        }
        let statusRemoved = deferFulfillment(removeStream) { _ in true }
        context.send(viewAction: .userStatus(.clear))
        
        // Then the clear user status endpoint should be called.
        try await statusRemoved.fulfill()
        #expect(clientProxy.clearUserStatusCallsCount == 1)
        #expect(!clientProxy.setUserStatusCalled)
    }
    
    @Test("An existing status is shown in the status row")
    mutating func showsExistingStatus() throws {
        // Given a screen where the user has a status set.
        let status = UserStatus.mockHoliday
        setupViewModel(status: status)
        
        // Then that status should be shown.
        let displayedStatus = try #require(status.displayed)
        #expect(context.viewState.userStatusRowMode == .showingStatus(displayedStatus))
    }
    
    @Test("Selecting a custom status emoji shows it, and cancelling resets it to the default")
    mutating func selectingCustomStatusEmoji() async throws {
        // Given a custom status field showing the default emoji.
        setupViewModel()
        context.send(viewAction: .userStatus(.customStatus))
        #expect(context.viewState.userStatusRowMode == .customStatusInput(emoji: "😄"))
        
        // When selecting an emoji from the picker.
        try await selectCustomStatusEmoji("🎉")
        
        // Then the custom status field should show the selected emoji.
        #expect(context.viewState.userStatusRowMode == .customStatusInput(emoji: "🎉"))
        
        // When cancelling and returning to the custom status field.
        context.send(viewAction: .userStatus(.cancel))
        context.send(viewAction: .userStatus(.customStatus))
        
        // Then the emoji should have been reset to the default.
        #expect(context.viewState.userStatusRowMode == .customStatusInput(emoji: "😄"))
    }
    
    @Test("Reporting a bug sends the report bug action")
    mutating func reportBug() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actions) { $0.isReportBug }
        context.send(viewAction: .reportBug)
        try await deferred.fulfill()
    }
    
    @Test("Opening analytics sends the analytics action")
    mutating func analytics() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actions) { $0.isAnalytics }
        context.send(viewAction: .analytics)
        try await deferred.fulfill()
    }
    
    @Test("Logging out sends the logout action")
    mutating func logout() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actions) { $0.isLogout }
        context.send(viewAction: .logout)
        try await deferred.fulfill()
    }
    
    // MARK: - Add account
    
    @Test("The switch accounts section shows only while multi-account is enabled")
    mutating func switchAccountsSectionFollowsTheFeatureFlag() async throws {
        let userSettings = UserSettings.mock()
        setupViewModel(userSettings: userSettings)
        #expect(!context.viewState.showSwitchAccountsSection)
        
        var deferred = deferFulfillment(context.observe(\.viewState.showSwitchAccountsSection)) { $0 }
        userSettings.app.multiAccountEnabled = true
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.observe(\.viewState.showSwitchAccountsSection)) { !$0 }
        userSettings.app.multiAccountEnabled = false
        try await deferred.fulfill()
    }
    
    @Test("Adding an account sends the add account action")
    mutating func addAccount() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actions) { $0.isAddAccount }
        context.send(viewAction: .addAccount)
        try await deferred.fulfill()
    }
    
    // MARK: - Switch accounts
    
    @Test("The other accounts are every account but this one, most recently used first, kept up to date")
    mutating func otherAccounts() async throws {
        let sessionDetails = CurrentValueSubject<[UserSessionDetails], Never>(makeSessionDetails(userIDs: ["@me:matrix.org", "@bob:matrix.org", "@alice:matrix.org"]))
        setupViewModel(availableSessionsPublisher: sessionDetails.asCurrentValuePublisher())
        #expect(context.viewState.otherAccounts.map(\.userID) == ["@bob:matrix.org", "@alice:matrix.org"])
        
        // E.g. Bob signed out.
        let deferred = deferFulfillment(context.observe(\.viewState.otherAccounts.count)) { $0 == 1 }
        sessionDetails.send(makeSessionDetails(userIDs: ["@me:matrix.org", "@alice:matrix.org"]))
        try await deferred.fulfill()
        #expect(context.viewState.otherAccounts.map(\.userID) == ["@alice:matrix.org"])
    }
    
    // MARK: - Helpers
    
    private func makeSessionDetails(userIDs: [String]) -> [UserSessionDetails] {
        userIDs.map { UserSessionDetails(userProfile: .init(userID: $0), unreadCount: 0, mediaProvider: MediaProviderMock(.init())) }
    }
    
    private mutating func setupViewModel(status: UserStatus = .init(),
                                         userSettings: UserSettings = .mock(),
                                         availableSessionsPublisher: CurrentValuePublisher<[UserSessionDetails], Never> = .init([])) {
        clientProxy = ClientProxyMock(.init(userID: "@me:matrix.org", status: status))
        viewModel = SettingsScreenViewModel(userSession: UserSessionMock(.init(clientProxy: clientProxy, userSettings: userSettings)),
                                            availableSessionsPublisher: availableSessionsPublisher,
                                            isBugReportServiceEnabled: true,
                                            isInSecondaryWindow: false,
                                            userIndicatorController: UserIndicatorControllerMock())
    }
    
    /// Shows the emoji picker and selects the provided emoji through its continuation.
    private func selectCustomStatusEmoji(_ emoji: String) async throws {
        let pickerPresented = deferFulfillment(viewModel.actions) { $0.isUserStatusEmojiPicker }
        context.send(viewAction: .userStatus(.pickCustomEmoji))
        guard case let .userStatusEmojiPicker(continuation) = try await pickerPresented.fulfill() else {
            Issue.record("Expected the emoji picker to be presented.")
            return
        }
        
        let emojiUpdated = deferFulfillment(context.observe(\.viewState.bindings.customStatusEmoji)) { $0 == Character(emoji) }
        continuation.yield(emoji)
        try await emojiUpdated.fulfill()
    }
}

private extension SettingsScreenViewModelAction {
    var isUserStatusEmojiPicker: Bool {
        switch self {
        case .userStatusEmojiPicker: true
        default: false
        }
    }
    
    var isReportBug: Bool {
        switch self {
        case .reportBug: true
        default: false
        }
    }
    
    var isAnalytics: Bool {
        switch self {
        case .analytics: true
        default: false
        }
    }
    
    var isLogout: Bool {
        switch self {
        case .logout: true
        default: false
        }
    }
    
    var isAddAccount: Bool {
        switch self {
        case .addAccount: true
        default: false
        }
    }
}
