//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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

    func testChangeSetting() {
        setUp(isSpace: false)
        // Given a screen with no changes.
        guard let index = context.settings[.roomDetails]?.firstIndex(where: { $0.keyPath == \.roomAvatar }) else {
            XCTFail("There should be a setting for the room avatar.")
            return
        }
        XCTAssertEqual(context.settings[.roomDetails]?[index].roleValue, .moderator)
        XCTAssertFalse(context.viewState.hasChanges)
        
        // When updating a setting.
        let setting = RoomPermissionsSetting(title: "",
                                             value: RoomRole.user.powerLevelValue,
                                             ownPowerLevel: RoomRole.creator.powerLevel,
                                             keyPath: \.roomAvatar)
        XCTAssertFalse(setting.isDisabled)
        XCTAssertEqual(setting.availableValues.map(\.tag), RoomPermissionsSetting.allValues.map(\.tag))
        context.settings[.roomDetails]?[index] = setting
        
        // Then the setting should update and the changes should be flagged.
        XCTAssertEqual(context.settings[.roomDetails]?[index].roleValue, .user)
        XCTAssertTrue(context.viewState.hasChanges)
    }
    
    func testSettingsCantBeChanged() {
        setUp(isSpace: false, ownPowerLevel: .value(25))
        // Given a screen with no changes.
        guard let index = context.settings[.roomDetails]?.firstIndex(where: { $0.keyPath == \.roomAvatar }) else {
            XCTFail("There should be a setting for the room avatar.")
            return
        }
        XCTAssertEqual(context.settings[.roomDetails]?[index].roleValue, .moderator)
        XCTAssertEqual(context.settings[.roomDetails]?[index].isDisabled, true)
        XCTAssertEqual(context.settings[.roomDetails]?[index].availableValues.count, 1)
        XCTAssertFalse(context.viewState.hasChanges)
        
        guard let index = context.settings[.messagesAndContent]?.firstIndex(where: { $0.keyPath == \.eventsDefault }) else {
            XCTFail("There should be a setting for the events.")
            return
        }
        XCTAssertEqual(context.settings[.messagesAndContent]?[index].roleValue, .user)
        XCTAssertEqual(context.settings[.messagesAndContent]?[index].isDisabled, false)
        XCTAssertEqual(context.settings[.messagesAndContent]?[index].availableValues.count, 1)
    }
    
    func testSave() async throws {
        setUp(isSpace: false)
        // Given a screen with changes.
        guard let index = context.settings[.roomDetails]?.firstIndex(where: { $0.keyPath == \.roomAvatar }) else {
            XCTFail("There should be a setting for the room avatar.")
            return
        }
        context.settings[.roomDetails]?[index] = RoomPermissionsSetting(title: "",
                                                                        value: RoomRole.user.powerLevelValue,
                                                                        ownPowerLevel: RoomRole.creator.powerLevel,
                                                                        keyPath: \.roomAvatar)
        XCTAssertEqual(context.settings[.roomDetails]?[index].roleValue, .user)
        XCTAssertEqual(context.settings[.roomDetails]?[index].isDisabled, false)
        XCTAssertEqual(context.settings[.roomDetails]?[index].availableValues.map(\.tag), RoomPermissionsSetting.allValues.map(\.tag))
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
        setUp(isSpace: false)
        // Given a screen with no changes.
        XCTAssertFalse(context.viewState.hasChanges)
        
        // When saving changes.
        context.send(viewAction: .save)
        
        // Then nothing should happen.
        XCTAssertFalse(roomProxy.applyPowerLevelChangesCalled)
    }
    
    func testDefaultStateRoom() async throws {
        setUp(isSpace: false)
        XCTAssertNotNil(context.settings[.roomDetails])
        XCTAssertNotNil(context.settings[.memberModeration])
        XCTAssertNotNil(context.settings[.messagesAndContent])
        XCTAssertNil(context.settings[.manageSpace])
    }
    
    func testDefaultStateSpace() async throws {
        setUp(isSpace: true)
        XCTAssertNotNil(context.settings[.roomDetails])
        XCTAssertNotNil(context.settings[.memberModeration])
        XCTAssertNil(context.settings[.messagesAndContent])
        XCTAssertNotNil(context.settings[.manageSpace])
    }
    
    private func setUp(isSpace: Bool, ownPowerLevel: RoomPowerLevel = RoomRole.creator.powerLevel) {
        roomProxy = JoinedRoomProxyMock(.init(isSpace: isSpace))
        viewModel = RoomChangePermissionsScreenViewModel(currentPermissions: .init(powerLevels: .mock),
                                                         ownPowerLevel: ownPowerLevel,
                                                         roomProxy: roomProxy,
                                                         userIndicatorController: UserIndicatorControllerMock(),
                                                         analytics: ServiceLocator.shared.analytics)
    }
}
