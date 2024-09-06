//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class RoomChangePermissionsScreenViewModelTests: XCTestCase {
    var roomProxy: JoinedRoomProxyMock!
    var viewModel: RoomChangePermissionsScreenViewModelProtocol!
    
    var context: RoomChangePermissionsScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUp() {
        roomProxy = JoinedRoomProxyMock(.init())
        viewModel = RoomChangePermissionsScreenViewModel(currentPermissions: .init(powerLevels: .mock),
                                                         group: .roomDetails,
                                                         roomProxy: roomProxy,
                                                         userIndicatorController: UserIndicatorControllerMock(),
                                                         analytics: ServiceLocator.shared.analytics)
    }

    func testChangeSetting() {
        // Given a screen with no changes.
        guard let index = context.settings.firstIndex(where: { $0.keyPath == \.roomAvatar }) else {
            XCTFail("There should be a setting for the room avatar.")
            return
        }
        XCTAssertEqual(context.settings[index].value, .moderator)
        XCTAssertFalse(context.viewState.hasChanges)
        
        // When updating a setting.
        let setting = RoomPermissionsSetting(title: "", value: .user, keyPath: \.roomAvatar)
        context.settings[index] = setting
        
        // Then the setting should update and the changes should be flagged.
        XCTAssertEqual(context.settings[index].value, .user)
        XCTAssertTrue(context.viewState.hasChanges)
    }
    
    func testSave() async throws {
        // Given a screen with changes.
        guard let index = context.settings.firstIndex(where: { $0.keyPath == \.roomAvatar }) else {
            XCTFail("There should be a setting for the room avatar.")
            return
        }
        context.settings[index] = RoomPermissionsSetting(title: "", value: .user, keyPath: \.roomAvatar)
        XCTAssertEqual(context.settings[index].value, .user)
        XCTAssertTrue(context.viewState.hasChanges)
        XCTAssertEqual(context.settings.count, 3)
        
        // When saving changes.
        context.send(viewAction: .save)
        // Nothing to await right now,
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the changes should be applied.
        XCTAssertTrue(roomProxy.applyPowerLevelChangesCalled)
        XCTAssertEqual(roomProxy.applyPowerLevelChangesReceivedChanges, .init(roomAvatar: 0),
                       "Only the avatar setting should be applied. No other settings were changed so they should be nil to remain left alone.")
    }
    
    func testSaveNoChanges() async throws {
        // Given a screen with no changes.
        XCTAssertFalse(context.viewState.hasChanges)
        
        // When saving changes.
        context.send(viewAction: .save)
        
        // Then nothing should happen.
        XCTAssertFalse(roomProxy.applyPowerLevelChangesCalled)
    }
}
