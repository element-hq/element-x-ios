//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite
final class JoinRoomScreenViewModelTests {
    private enum TestMode {
        case joined
        case knocked
        case invited
        case banned
    }
    
    var viewModel: JoinRoomScreenViewModelProtocol!
    
    var clientProxy: ClientProxyMock!
    var appSettings: AppSettings!
    
    var context: JoinRoomScreenViewModelType.Context {
        viewModel.context
    }
    
    init() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        ServiceLocator.shared.register(appSettings: appSettings)
    }
    
    deinit {
        viewModel = nil
        clientProxy = nil
        AppSettings.resetAllSettings()
    }
    
    @Test
    func interaction() async throws {
        #expect(appSettings.seenInvites.isEmpty, "There shouldn't be any seen invites before running the tests.")
        
        setupViewModel()
        try await deferFulfillment(viewModel.context.$viewState) { $0.mode == .joinable }.fulfill()
        
        #expect(appSettings.seenInvites.isEmpty, "Only an invited room should register the room ID as a seen invite.")
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .joined(.roomID("1")) }
        context.send(viewAction: .join)
        try await deferred.fulfill()
    }
    
    @Test
    func acceptInviteInteraction() async throws {
        #expect(appSettings.seenInvites.isEmpty, "There shouldn't be any seen invites before running the tests.")
        
        setupViewModel(mode: .invited)
        try await deferFulfillment(viewModel.context.$viewState) { $0.mode == .invited(isDM: false) }.fulfill()
        
        #expect(appSettings.seenInvites == ["1"], "The invited room's ID should be registered as a seen invite.")
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .joined(.roomID("1")) }
        context.send(viewAction: .acceptInvite)
        try await deferred.fulfill()
        
        #expect(appSettings.seenInvites.isEmpty, "The after accepting an invite the invite should be forgotten in case the user leaves.")
    }
    
    @Test
    func declineInviteInteraction() async throws {
        #expect(appSettings.seenInvites.isEmpty, "There shouldn't be any seen invites before running the tests.")
        
        setupViewModel(mode: .invited)
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.mode == .invited(isDM: false) }.fulfill()
        #expect(appSettings.seenInvites == ["1"], "The invited room's ID should be registered as a seen invite.")
        
        context.send(viewAction: .declineInvite)
        
        #expect(viewModel.context.alertInfo?.id == .declineInvite)
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .dismiss }
        context.alertInfo?.secondaryButton?.action?()
        try await deferred.fulfill()
        
        #expect(appSettings.seenInvites.isEmpty, "The after declining an invite the invite should be forgotten in case another invite is received.")
    }
    
    @Test
    func knockedState() async throws {
        #expect(appSettings.seenInvites.isEmpty, "There shouldn't be any seen invites before running the tests.")
        setupViewModel(mode: .knocked)
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.mode == .knocked }.fulfill()
        
        #expect(appSettings.seenInvites.isEmpty, "Only an invited room should register the room ID as a seen invite.")
    }
    
    @Test
    func cancelKnock() async throws {
        setupViewModel(mode: .knocked)
        
        try await deferFulfillment(viewModel.context.$viewState) { state in
            state.mode == .knocked
        }.fulfill()
        
        context.send(viewAction: .cancelKnock)
        #expect(viewModel.context.alertInfo?.id == .cancelKnock)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss
        }
        context.alertInfo?.secondaryButton?.action?()
        try await deferred.fulfill()
    }
    
    @Test
    func declineAndBlockInviteLegacyInteraction() async throws {
        setupViewModel(mode: .invited)
        clientProxy.underlyingIsReportRoomSupported = false
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.roomDetails != nil }.fulfill()
        
        context.send(viewAction: .declineInviteAndBlock(userID: "@test:matrix.org"))
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.bindings.alertInfo != nil }.fulfill()
        #expect(viewModel.context.alertInfo?.id == .declineInviteAndBlock)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss
        }
        
        await confirmation("Wait for the user to be ignored") { confirm in
            clientProxy.ignoreUserClosure = { userID in
                defer { confirm() }
                #expect(userID == "@test:matrix.org")
                return .success(())
            }
            context.alertInfo?.secondaryButton?.action?()
            try await deferred.fulfill()
        }
    }
    
    @Test
    func declineAndBlockInviteInteraction() async throws {
        setupViewModel(mode: .invited)
        try await deferFulfillment(viewModel.context.$viewState) { $0.roomDetails != nil }.fulfill()
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { $0 == .presentDeclineAndBlock(userID: "@test:matrix.org") }
        context.send(viewAction: .declineInviteAndBlock(userID: "@test:matrix.org"))
        try await deferredAction.fulfill()
    }
    
    @Test
    func forgetRoom() async throws {
        setupViewModel(mode: .banned)
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.roomDetails != nil }.fulfill()
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss
        }
        context.send(viewAction: .forget)
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(throwing: Bool = false, mode: TestMode = .joined) {
        ServiceLocator.shared.settings.knockingEnabled = true
        
        clientProxy = ClientProxyMock(.init())
        
        clientProxy.joinRoomViaReturnValue = throwing ? .failure(.sdkError(ClientProxyMockError.generic)) : .success(())
        clientProxy.joinRoomAliasReturnValue = clientProxy.joinRoomViaReturnValue
        
        switch mode {
        case .knocked:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.knocked)
            
            clientProxy.roomForIdentifierClosure = { _ in
                let roomProxy = KnockedRoomProxyMock(.init())
                // to test the cancel knock function
                roomProxy.cancelKnockUnderlyingReturnValue = .success(())
                return .knocked(roomProxy)
            }
        case .joined:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.joinable)
        case .invited:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.invited())
            clientProxy.roomForIdentifierClosure = { _ in
                let roomProxy = InvitedRoomProxyMock(.init())
                roomProxy.rejectInvitationReturnValue = .success(())
                return .invited(roomProxy)
            }
        case .banned:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.banned)
            clientProxy.roomForIdentifierClosure = { _ in
                let roomProxy = BannedRoomProxyMock(.init())
                roomProxy.forgetRoomReturnValue = .success(())
                return .banned(roomProxy)
            }
        }
        
        viewModel = JoinRoomScreenViewModel(source: .generic(roomID: "1", via: []),
                                            appSettings: appSettings,
                                            userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}

extension JoinRoomScreenViewModelAction: @retroactive Equatable {
    /// A close enough approximation for tests.
    public static func == (lhs: JoinRoomScreenViewModelAction, rhs: JoinRoomScreenViewModelAction) -> Bool {
        switch (lhs, rhs) {
        case (.joined(.roomID(let lhsRoomID)), .joined(.roomID(let rhsRoomID))):
            lhsRoomID == rhsRoomID
        case (.joined(.space(let lhsSpace)), .joined(.space(let rhsSpace))):
            lhsSpace.id == rhsSpace.id
        case (.dismiss, .dismiss):
            true
        case (.presentDeclineAndBlock(let lhsUserID), .presentDeclineAndBlock(let rhsUserID)):
            lhsUserID == rhsUserID
        default:
            false
        }
    }
}
