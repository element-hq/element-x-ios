//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDK
import XCTest

@MainActor
class SecurityAndPrivacyScreenViewModelTests: XCTestCase {
    var viewModel: SecurityAndPrivacyScreenViewModelProtocol!
    var spaceServiceProxy: SpaceServiceProxyMock!
    var roomProxy: JoinedRoomProxyMock!
    
    var context: SecurityAndPrivacyScreenViewModelType.Context {
        viewModel.context
    }
    
    override func tearDown() {
        viewModel = nil
        roomProxy = nil
        AppSettings.resetAllSettings()
    }
    
    func testSetSingleJoinedSpaceMembersAccess() async throws {
        let singleRoom = [SpaceServiceRoom].mockSingleRoom
        let space = singleRoom[0]
        setupViewModel(joinedParentSpaces: singleRoom, joinRule: .public)
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableJoinedSpaces.count == 1 }
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.currentSettings.accessType, .anyone)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertTrue(context.viewState.isSpaceMembersOptionSelectable)
        guard case .singleJoined = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .singleJoined")
            return
        }
        
        context.send(viewAction: .selectedSpaceMembersAccess)
        XCTAssertEqual(context.desiredSettings.accessType, .spaceMembers(spaceIDs: [space.id]))
        XCTAssertFalse(context.viewState.shouldShowAccessSectionFooter)
        XCTAssertFalse(context.viewState.isSaveDisabled)
        
        let expectation = expectation(description: "Join rule has updated")
        roomProxy.updateJoinRuleClosure = { value in
            XCTAssertEqual(value, .restricted(rules: [.roomMembership(roomID: space.id)]))
            expectation.fulfill()
            return .success(())
        }
        context.send(viewAction: .save)
        await fulfillment(of: [expectation])
    }
    
    func testSetSingleJoinedAskToJoinWithSpaceMembersAccess() async throws {
        let singleRoom = [SpaceServiceRoom].mockSingleRoom
        let space = singleRoom[0]
        setupViewModel(joinedParentSpaces: singleRoom, joinRule: .public)
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableJoinedSpaces.count == 1 }
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.currentSettings.accessType, .anyone)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertTrue(context.viewState.isAskToJoinWithSpaceMembersOptionSelectable)
        guard case .singleJoined = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .singleJoined")
            return
        }
        
        context.send(viewAction: .selectedAskToJoinWithSpaceMembersAccess)
        XCTAssertEqual(context.desiredSettings.accessType, .askToJoinWithSpaceMembers(spaceIDs: [space.id]))
        XCTAssertFalse(context.viewState.shouldShowAccessSectionFooter)
        XCTAssertFalse(context.viewState.isSaveDisabled)
        
        let expectation = expectation(description: "Join rule has updated")
        roomProxy.updateJoinRuleClosure = { value in
            XCTAssertEqual(value, .knockRestricted(rules: [.roomMembership(roomID: space.id)]))
            expectation.fulfill()
            return .success(())
        }
        context.send(viewAction: .save)
        await fulfillment(of: [expectation])
    }
    
    func testSingleUnknownSpaceMembersAccessCanBeReselected() async throws {
        let singleRoom = [SpaceServiceRoom].mockSingleRoom
        let space = singleRoom[0]
        setupViewModel(joinedParentSpaces: [], joinRule: .restricted(rules: [.roomMembership(roomID: space.id)]))
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableJoinedSpaces.count == 0 }
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.currentSettings.accessType, .spaceMembers(spaceIDs: [space.id]))
        XCTAssertEqual(context.desiredSettings, context.viewState.currentSettings)
        XCTAssertTrue(context.viewState.isSpaceMembersOptionSelectable)
        XCTAssertFalse(context.viewState.shouldShowAccessSectionFooter)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        guard case .singleUnknown = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .singleUnknown")
            return
        }
        
        context.desiredSettings.accessType = .anyone
        XCTAssertTrue(context.viewState.isSpaceMembersOptionSelectable)
        XCTAssertFalse(context.viewState.isSaveDisabled)
        
        context.send(viewAction: .selectedSpaceMembersAccess)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertEqual(context.desiredSettings.accessType, .spaceMembers(spaceIDs: [space.id]))
        guard case .singleUnknown = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .singleUnknown")
            return
        }
    }
    
    func testMultipleKnownSpacesMembersSelection() async throws {
        let spaces = [SpaceServiceRoom].mockJoinedSpaces2
        setupViewModel(joinedParentSpaces: spaces, joinRule: .public)
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableJoinedSpaces.count == 3 }
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.currentSettings.accessType, .anyone)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertTrue(context.viewState.isSpaceMembersOptionSelectable)
        guard case .multiple = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .multiple")
            return
        }
        
        var selectedIDs: PassthroughSubject<Set<String>, Never>!
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            switch action {
            case .displayManageAuthorizedSpacesScreen(let authorizedSpacesSelection):
                defer { selectedIDs = authorizedSpacesSelection.selectedIDs }
                return authorizedSpacesSelection.joinedSpaces.map(\.id) == spaces.map(\.id) &&
                    authorizedSpacesSelection.unknownSpacesIDs.isEmpty &&
                    authorizedSpacesSelection.initialSelectedIDs.isEmpty
            default:
                return false
            }
        }
        context.send(viewAction: .selectedSpaceMembersAccess)
        try await deferredAction.fulfill()
        selectedIDs.send([spaces[0].id])
        XCTAssertEqual(context.desiredSettings.accessType, .spaceMembers(spaceIDs: [spaces[0].id]))
        XCTAssertTrue(context.viewState.shouldShowAccessSectionFooter)
        XCTAssertFalse(context.viewState.isSaveDisabled)

        let expectation = expectation(description: "Join rule has updated")
        roomProxy.updateJoinRuleClosure = { value in
            XCTAssertEqual(value, .restricted(rules: [.roomMembership(roomID: spaces[0].id)]))
            expectation.fulfill()
            return .success(())
        }
        context.send(viewAction: .save)
        await fulfillment(of: [expectation])
    }
    
    func testMultipleKnownAskToJoinSpacesMembersSelection() async throws {
        let spaces = [SpaceServiceRoom].mockJoinedSpaces2
        setupViewModel(joinedParentSpaces: spaces, joinRule: .public)
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableJoinedSpaces.count == 3 }
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.currentSettings.accessType, .anyone)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertTrue(context.viewState.isAskToJoinWithSpaceMembersOptionSelectable)
        guard case .multiple = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .multiple")
            return
        }
        
        var selectedIDs: PassthroughSubject<Set<String>, Never>!
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            switch action {
            case .displayManageAuthorizedSpacesScreen(let authorizedSpacesSelection):
                defer { selectedIDs = authorizedSpacesSelection.selectedIDs }
                return authorizedSpacesSelection.joinedSpaces.map(\.id) == spaces.map(\.id) &&
                    authorizedSpacesSelection.unknownSpacesIDs.isEmpty &&
                    authorizedSpacesSelection.initialSelectedIDs.isEmpty
            default:
                return false
            }
        }
        context.send(viewAction: .selectedAskToJoinWithSpaceMembersAccess)
        try await deferredAction.fulfill()
        selectedIDs.send([spaces[0].id])
        XCTAssertEqual(context.desiredSettings.accessType, .askToJoinWithSpaceMembers(spaceIDs: [spaces[0].id]))
        XCTAssertTrue(context.viewState.shouldShowAccessSectionFooter)
        XCTAssertFalse(context.viewState.isSaveDisabled)

        let expectation = expectation(description: "Join rule has updated")
        roomProxy.updateJoinRuleClosure = { value in
            XCTAssertEqual(value, .knockRestricted(rules: [.roomMembership(roomID: spaces[0].id)]))
            expectation.fulfill()
            return .success(())
        }
        context.send(viewAction: .save)
        await fulfillment(of: [expectation])
    }
    
    func testMultipleSpacesMembersSelection() async throws {
        let spaces = [SpaceServiceRoom].mockJoinedSpaces2
        setupViewModel(joinedParentSpaces: spaces,
                       joinRule: .restricted(rules: [.roomMembership(roomID: "unknownSpaceID")]))
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableSpacesCount == 4 }
        try await deferred.fulfill()
        
        XCTAssertTrue(context.viewState.currentSettings.accessType.isSpaceMembers)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertTrue(context.viewState.isSpaceMembersOptionSelectable)
        guard case .multiple = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .multiple")
            return
        }
        
        var selectedIDs: PassthroughSubject<Set<String>, Never>!
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            switch action {
            case .displayManageAuthorizedSpacesScreen(let authorizedSpacesSelection):
                // We need the
                defer { selectedIDs = authorizedSpacesSelection.selectedIDs }
                return authorizedSpacesSelection.joinedSpaces.map(\.id) == spaces.map(\.id) &&
                    authorizedSpacesSelection.unknownSpacesIDs == ["unknownSpaceID"] &&
                    authorizedSpacesSelection.initialSelectedIDs == ["unknownSpaceID"]
            default:
                return false
            }
        }
        context.send(viewAction: .manageSpaces)
        try await deferredAction.fulfill()
        selectedIDs.send([spaces[0].id, "unknownSpaceID"])
        XCTAssertEqual(context.desiredSettings.accessType, .spaceMembers(spaceIDs: [spaces[0].id, "unknownSpaceID"]))
        XCTAssertTrue(context.viewState.shouldShowAccessSectionFooter)
        XCTAssertFalse(context.viewState.isSaveDisabled)

        let expectation = expectation(description: "Join rule has updated")
        roomProxy.updateJoinRuleClosure = { value in
            XCTAssertEqual(value, .restricted(rules: [.roomMembership(roomID: spaces[0].id), .roomMembership(roomID: "unknownSpaceID")]))
            expectation.fulfill()
            return .success(())
        }
        context.send(viewAction: .save)
        await fulfillment(of: [expectation])
    }
    
    func testMultipleSpacesMembersSelectionWithAnExistingNonParentButJoinedSpace() async throws {
        let joinedParentSpaces = [SpaceServiceRoom].mockJoinedSpaces2
        let singleRoom = [SpaceServiceRoom].mockSingleRoom
        let space = singleRoom[0]
        let allSpaces = joinedParentSpaces + singleRoom
        setupViewModel(joinedParentSpaces: joinedParentSpaces,
                       topLevelSpaces: allSpaces,
                       joinRule: .restricted(rules: [.roomMembership(roomID: space.id),
                                                     .roomMembership(roomID: "unknownSpaceID")]))
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableSpacesCount == 5 }
        try await deferred.fulfill()
        
        XCTAssertTrue(context.viewState.currentSettings.accessType.isSpaceMembers)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertTrue(context.viewState.isSpaceMembersOptionSelectable)
        guard case .multiple = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .multiple")
            return
        }
        
        var selectedIDs: PassthroughSubject<Set<String>, Never>!
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            switch action {
            case .displayManageAuthorizedSpacesScreen(let authorizedSpacesSelection):
                // We need the
                defer { selectedIDs = authorizedSpacesSelection.selectedIDs }
                return authorizedSpacesSelection.joinedSpaces.map(\.id) == allSpaces.map(\.id) &&
                    authorizedSpacesSelection.unknownSpacesIDs == ["unknownSpaceID"] &&
                    authorizedSpacesSelection.initialSelectedIDs == [space.id, "unknownSpaceID"]
            default:
                return false
            }
        }
        context.send(viewAction: .manageSpaces)
        try await deferredAction.fulfill()
        selectedIDs.send([allSpaces[0].id, "unknownSpaceID"])
        XCTAssertEqual(context.desiredSettings.accessType, .spaceMembers(spaceIDs: [allSpaces[0].id, "unknownSpaceID"]))
        XCTAssertTrue(context.viewState.shouldShowAccessSectionFooter)
        XCTAssertFalse(context.viewState.isSaveDisabled)
    }
    
    func testEmptySpaceMembersSelectionEdgeCase() async throws {
        // Edge case where there is no available joined parents and the room has a restricted join rule.
        // With no space ids in it
        setupViewModel(joinedParentSpaces: [],
                       joinRule: .restricted(rules: []))
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableSpacesCount == 0 }
        try await deferred.fulfill()
        
        XCTAssertTrue(context.viewState.currentSettings.accessType.isSpaceMembers)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertFalse(context.viewState.isSpaceMembersOptionSelectable)
        XCTAssertFalse(context.viewState.shouldShowAccessSectionFooter)
        guard case .empty = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .empty")
            return
        }
    }
    
    func testEmptySpaceMembersSelectionWithJoinedParentEdgeCase() async throws {
        // Edge case where there is one available joined parent but the room has a restricted join rule.
        // With no space ids in it
        let singleRoom = [SpaceServiceRoom].mockSingleRoom
        setupViewModel(joinedParentSpaces: singleRoom,
                       joinRule: .restricted(rules: []))
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableSpacesCount == 1 }
        try await deferred.fulfill()
        
        XCTAssertTrue(context.viewState.currentSettings.accessType.isSpaceMembers)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertTrue(context.viewState.isSpaceMembersOptionSelectable)
        XCTAssertTrue(context.viewState.shouldShowAccessSectionFooter)
        guard case .multiple = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .multiple")
            return
        }
        
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            switch action {
            case .displayManageAuthorizedSpacesScreen(let authorizedSpacesSelection):
                return authorizedSpacesSelection.joinedSpaces.map(\.id) == singleRoom.map(\.id) &&
                    authorizedSpacesSelection.unknownSpacesIDs.isEmpty &&
                    authorizedSpacesSelection.initialSelectedIDs.isEmpty
            default:
                return false
            }
        }
        context.send(viewAction: .manageSpaces)
        try await deferredAction.fulfill()
    }
    
    func testSave() async throws {
        setupViewModel(joinedParentSpaces: [], joinRule: .public)
        
        // Saving shouldn't dismiss this screen (or trigger any other action).
        let deferred = deferFailure(viewModel.actionsPublisher, timeout: 1) { _ in true }
        
        context.desiredSettings.accessType = .inviteOnly
        context.send(viewAction: .save)
        
        try await deferred.fulfill()
    }
    
    func testCancelWithChangesAndDiscard() async throws {
        setupViewModel(joinedParentSpaces: [], joinRule: .public)
        context.desiredSettings.accessType = .inviteOnly
        XCTAssertFalse(context.viewState.isSaveDisabled)
        XCTAssertNil(context.alertInfo)
        
        context.send(viewAction: .cancel)
        
        XCTAssertNotNil(context.alertInfo)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) {
            switch $0 {
            case .dismiss:
                true
            default:
                false
            }
        }
        context.alertInfo?.secondaryButton?.action?() // Discard
        try await deferred.fulfill()
    }
    
    func testCancelWithChangesAndSave() async throws {
        setupViewModel(joinedParentSpaces: [], joinRule: .public)
        context.desiredSettings.accessType = .inviteOnly
        XCTAssertFalse(context.viewState.isSaveDisabled)
        XCTAssertNil(context.alertInfo)
        
        context.send(viewAction: .cancel)
        
        XCTAssertNotNil(context.alertInfo)
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) {
            switch $0 {
            case .dismiss:
                true
            default:
                false
            }
        }
        context.alertInfo?.primaryButton.action?() // Save
        try await deferred.fulfill()
    }
    
    func testCancelWithChangesAndSaveWithFailure() async throws {
        setupViewModel(joinedParentSpaces: [], joinRule: .public)
        roomProxy.updateJoinRuleReturnValue = .failure(.sdkError(RoomProxyMockError.generic))
        context.desiredSettings.accessType = .inviteOnly
        XCTAssertFalse(context.viewState.isSaveDisabled)
        XCTAssertNil(context.alertInfo)
        
        context.send(viewAction: .cancel)
        
        XCTAssertNotNil(context.alertInfo)
        
        // The screen should not be dismissed if a failure occurred.
        let deferred = deferFailure(viewModel.actionsPublisher, timeout: 1) { _ in true }
        context.alertInfo?.primaryButton.action?() // Save
        try await deferred.fulfill()
    }
    
    // MARK: - Helpers
    
    private func setupViewModel(joinedParentSpaces: [SpaceServiceRoom],
                                topLevelSpaces: [SpaceServiceRoom] = [],
                                joinRule: ElementX.JoinRule) {
        let appSettings = AppSettings()
        appSettings.spaceSettingsEnabled = true
        appSettings.knockingEnabled = true
        roomProxy = JoinedRoomProxyMock(.init(isEncrypted: false,
                                              canonicalAlias: "#room:matrix.org",
                                              members: .allMembersAsCreator,
                                              joinRule: joinRule,
                                              isVisibleInPublicDirectory: true))
        roomProxy.updateJoinRuleReturnValue = .success(())
        roomProxy.updateRoomDirectoryVisibilityReturnValue = .success(())
        
        viewModel = SecurityAndPrivacyScreenViewModel(roomProxy: roomProxy,
                                                      clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org",
                                                                                         spaceServiceConfiguration: .init(topLevelSpaces: topLevelSpaces,
                                                                                                                          joinedParentSpaces: joinedParentSpaces))),
                                                      userIndicatorController: UserIndicatorControllerMock(),
                                                      appSettings: appSettings)
    }
}
