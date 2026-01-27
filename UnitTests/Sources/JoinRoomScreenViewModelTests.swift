//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class JoinRoomScreenViewModelTests: XCTestCase {
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
    
    override func setUp() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        ServiceLocator.shared.register(appSettings: appSettings)
    }
    
    override func tearDown() {
        viewModel = nil
        clientProxy = nil
        AppSettings.resetAllSettings()
    }

    func testInteraction() async throws {
        XCTAssertTrue(appSettings.seenInvites.isEmpty, "There shouldn't be any seen invites before running the tests.")
        
        setupViewModel()
        try await deferFulfillment(viewModel.context.$viewState) { $0.mode == .joinable }.fulfill()
        
        XCTAssertTrue(appSettings.seenInvites.isEmpty, "Only an invited room should register the room ID as a seen invite.")
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .joined(.roomID("1")) }
        context.send(viewAction: .join)
        try await deferred.fulfill()
    }
    
    func testAcceptInviteInteraction() async throws {
        XCTAssertTrue(appSettings.seenInvites.isEmpty, "There shouldn't be any seen invites before running the tests.")
        
        setupViewModel(mode: .invited)
        try await deferFulfillment(viewModel.context.$viewState) { $0.mode == .invited(isDM: false) }.fulfill()
        
        XCTAssertEqual(appSettings.seenInvites, ["1"], "The invited room's ID should be registered as a seen invite.")
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .joined(.roomID("1")) }
        context.send(viewAction: .acceptInvite)
        try await deferred.fulfill()
        
        XCTAssertTrue(appSettings.seenInvites.isEmpty, "The after accepting an invite the invite should be forgotten in case the user leaves.")
    }
    
    func testDeclineInviteInteraction() async throws {
        XCTAssertTrue(appSettings.seenInvites.isEmpty, "There shouldn't be any seen invites before running the tests.")
        
        setupViewModel(mode: .invited)
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.mode == .invited(isDM: false) }.fulfill()
        XCTAssertEqual(appSettings.seenInvites, ["1"], "The invited room's ID should be registered as a seen invite.")
        
        context.send(viewAction: .declineInvite)
        
        XCTAssertEqual(viewModel.context.alertInfo?.id, .declineInvite)
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .dismiss }
        context.alertInfo?.secondaryButton?.action?()
        try await deferred.fulfill()
        
        XCTAssertTrue(appSettings.seenInvites.isEmpty, "The after declining an invite the invite should be forgotten in case another invite is received.")
    }
    
    func testKnockedState() async throws {
        XCTAssertTrue(appSettings.seenInvites.isEmpty, "There shouldn't be any seen invites before running the tests.")
        setupViewModel(mode: .knocked)
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.mode == .knocked }.fulfill()
        
        XCTAssertTrue(appSettings.seenInvites.isEmpty, "Only an invited room should register the room ID as a seen invite.")
    }
    
    func testCancelKnock() async throws {
        setupViewModel(mode: .knocked)
        
        try await deferFulfillment(viewModel.context.$viewState) { state in
            state.mode == .knocked
        }.fulfill()
        
        context.send(viewAction: .cancelKnock)
        XCTAssertEqual(viewModel.context.alertInfo?.id, .cancelKnock)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss
        }
        context.alertInfo?.secondaryButton?.action?()
        try await deferred.fulfill()
    }
    
    func testDeclineAndBlockInviteLegacyInteraction() async throws {
        setupViewModel(mode: .invited)
        clientProxy.underlyingIsReportRoomSupported = false
        let expectation = expectation(description: "Wait for the user to be ignored")
        clientProxy.ignoreUserClosure = { userID in
            defer { expectation.fulfill() }
            XCTAssertEqual(userID, "@test:matrix.org")
            return .success(())
        }
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.roomDetails != nil }.fulfill()
        
        context.send(viewAction: .declineInviteAndBlock(userID: "@test:matrix.org"))
        
        try await deferFulfillment(viewModel.context.$viewState) { $0.bindings.alertInfo != nil }.fulfill()
        XCTAssertEqual(viewModel.context.alertInfo?.id, .declineInviteAndBlock)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss
        }
        context.alertInfo?.secondaryButton?.action?()
        await fulfillment(of: [expectation], timeout: 10)
        try await deferred.fulfill()
    }
    
    func testDeclineAndBlockInviteInteraction() async throws {
        setupViewModel(mode: .invited)
        try await deferFulfillment(viewModel.context.$viewState) { $0.roomDetails != nil }.fulfill()
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { $0 == .presentDeclineAndBlock(userID: "@test:matrix.org") }
        context.send(viewAction: .declineInviteAndBlock(userID: "@test:matrix.org"))
        try await deferredAction.fulfill()
    }
    
    func testForgetRoom() async throws {
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
