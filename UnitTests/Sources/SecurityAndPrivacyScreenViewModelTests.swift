//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import XCTest

@testable import ElementX

@MainActor
class SecurityAndPrivacyScreenViewModelTests: XCTestCase {
    var viewModel: SecurityAndPrivacyScreenViewModelProtocol!
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
        let singleRoom = [SpaceRoomProxyProtocol].mockSingleRoom
        let space = singleRoom[0]
        setupViewModel(isSpaceSettingsEnabled: true, joinedParentSpaces: singleRoom, joinRule: .public)
        
        let deferred = deferFulfillment(context.$viewState) { $0.joinedParentSpaces.count == 1 }
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.currentSettings.accessType, .anyone)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertTrue(context.viewState.isSpaceMembersOptionSelectable)
        guard case .singleJoined = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .singleSpace")
            return
        }
        
        context.send(viewAction: .selectedSpaceMembersAccess)
        XCTAssertEqual(context.desiredSettings.accessType, .spaceUsers(spaceIDs: [space.id]))
        XCTAssertNil(context.viewState.accessSectionFooter)
        XCTAssertFalse(context.viewState.isSaveDisabled)
        
        let expectation = expectation(description: "Join rule has updated")
        roomProxy.updateJoinRuleClosure = { value in
            XCTAssertEqual(value, .restricted(rules: [.roomMembership(roomId: space.id)]))
            expectation.fulfill()
            return .success(())
        }
        context.send(viewAction: .save)
        await fulfillment(of: [expectation])
    }
    
    func testSingleUnknownSpaceMembersAccessCanBeReselected() async throws {
        let singleRoom = [SpaceRoomProxyProtocol].mockSingleRoom
        let space = singleRoom[0]
        setupViewModel(isSpaceSettingsEnabled: true, joinedParentSpaces: [], joinRule: .restricted(rules: [.roomMembership(roomId: space.id)]))
        
        let deferred = deferFulfillment(context.$viewState) { $0.joinedParentSpaces.count == 0 }
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.currentSettings.accessType, .spaceUsers(spaceIDs: [space.id]))
        XCTAssertEqual(context.desiredSettings, context.viewState.currentSettings)
        XCTAssertTrue(context.viewState.isSpaceMembersOptionSelectable)
        XCTAssertNil(context.viewState.accessSectionFooter)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        guard case .singleUnknown = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .singleSpace")
            return
        }
        
        context.desiredSettings.accessType = .anyone
        XCTAssertTrue(context.viewState.isSpaceMembersOptionSelectable)
        XCTAssertFalse(context.viewState.isSaveDisabled)
        
        context.send(viewAction: .selectedSpaceMembersAccess)
        XCTAssertTrue(context.viewState.isSaveDisabled)
        XCTAssertEqual(context.desiredSettings.accessType, .spaceUsers(spaceIDs: [space.id]))
        guard case .singleUnknown = context.viewState.spaceSelection else {
            XCTFail("Expected spaceSelection to be .singleSpace")
            return
        }
    }
    
    private func setupViewModel(isSpaceSettingsEnabled: Bool,
                                joinedParentSpaces: [SpaceRoomProxyProtocol],
                                joinRule: JoinRule) {
        let appSettings = AppSettings()
        appSettings.spaceSettingsEnabled = isSpaceSettingsEnabled
        roomProxy = JoinedRoomProxyMock(.init(isEncrypted: false,
                                              canonicalAlias: "#room:matrix.org",
                                              members: .allMembersAsCreator,
                                              joinRule: joinRule,
                                              isVisibleInPublicDirectory: true))
        
        viewModel = SecurityAndPrivacyScreenViewModel(roomProxy: roomProxy,
                                                      clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org",
                                                                                         spaceServiceConfiguration: .init(joinedParentSpaces: joinedParentSpaces))),
                                                      userIndicatorController: UserIndicatorControllerMock(),
                                                      appSettings: appSettings)
    }
}
