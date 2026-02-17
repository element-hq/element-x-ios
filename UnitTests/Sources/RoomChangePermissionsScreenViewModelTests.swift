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
struct RoomChangePermissionsScreenViewModelTests {
    @MainActor
    private struct TestSetup {
        var roomProxy: JoinedRoomProxyMock
        var viewModel: RoomChangePermissionsScreenViewModelProtocol
        
        var context: RoomChangePermissionsScreenViewModelType.Context {
            viewModel.context
        }
        
        init(isSpace: Bool, ownPowerLevel: RoomPowerLevel = RoomRole.creator.powerLevel) {
            roomProxy = JoinedRoomProxyMock(.init(isSpace: isSpace))
            viewModel = RoomChangePermissionsScreenViewModel(currentPermissions: .init(powerLevels: .mock),
                                                             ownPowerLevel: ownPowerLevel,
                                                             roomProxy: roomProxy,
                                                             userIndicatorController: UserIndicatorControllerMock(),
                                                             analytics: ServiceLocator.shared.analytics)
        }
    }

    @Test
    func changeSetting() throws {
        let testSetup = TestSetup(isSpace: false)
        // Given a screen with no changes.
        let index = try #require(testSetup.context.settings[.roomDetails]?.firstIndex { $0.keyPath == \.roomAvatar },
                                 "There should be a setting for the room avatar.")
        #expect(testSetup.context.settings[.roomDetails]?[index].roleValue == .moderator)
        #expect(!testSetup.context.viewState.hasChanges)
        
        // When updating a setting.
        let setting = RoomPermissionsSetting(title: "",
                                             value: RoomRole.user.powerLevelValue,
                                             ownPowerLevel: RoomRole.creator.powerLevel,
                                             keyPath: \.roomAvatar)
        #expect(!setting.isDisabled)
        #expect(setting.availableValues.map(\.tag) == RoomPermissionsSetting.allValues.map(\.tag))
        testSetup.context.settings[.roomDetails]?[index] = setting
        
        // Then the setting should update and the changes should be flagged.
        #expect(testSetup.context.settings[.roomDetails]?[index].roleValue == .user)
        #expect(testSetup.context.viewState.hasChanges)
    }
    
    @Test
    func settingsCantBeChanged() throws {
        let testSetup = TestSetup(isSpace: false, ownPowerLevel: .value(25))
        // Given a screen with no changes.
        var index = try #require(testSetup.context.settings[.roomDetails]?.firstIndex { $0.keyPath == \.roomAvatar },
                                 "There should be a setting for the room avatar.")
        #expect(testSetup.context.settings[.roomDetails]?[index].roleValue == .moderator)
        #expect(testSetup.context.settings[.roomDetails]?[index].isDisabled == true)
        #expect(testSetup.context.settings[.roomDetails]?[index].availableValues.count == 1)
        #expect(!testSetup.context.viewState.hasChanges)
        
        index = try #require(testSetup.context.settings[.messagesAndContent]?.firstIndex { $0.keyPath == \.eventsDefault },
                             "There should be a setting for the events.")
        #expect(testSetup.context.settings[.messagesAndContent]?[index].roleValue == .user)
        #expect(testSetup.context.settings[.messagesAndContent]?[index].isDisabled == false)
        #expect(testSetup.context.settings[.messagesAndContent]?[index].availableValues.count == 1)
    }
    
    @Test
    func save() async throws {
        let testSetup = TestSetup(isSpace: false)
        // Given a screen with changes.
        let index = try #require(testSetup.context.settings[.roomDetails]?.firstIndex { $0.keyPath == \.roomAvatar },
                                 "There should be a setting for the room avatar.")
        testSetup.context.settings[.roomDetails]?[index] = RoomPermissionsSetting(title: "",
                                                                                  value: RoomRole.user.powerLevelValue,
                                                                                  ownPowerLevel: RoomRole.creator.powerLevel,
                                                                                  keyPath: \.roomAvatar)
        #expect(testSetup.context.settings[.roomDetails]?[index].roleValue == .user)
        #expect(testSetup.context.settings[.roomDetails]?[index].isDisabled == false)
        #expect(testSetup.context.settings[.roomDetails]?[index].availableValues.map(\.tag) == RoomPermissionsSetting.allValues.map(\.tag))
        #expect(testSetup.context.viewState.hasChanges)
        #expect(testSetup.context.settings.count == 3)
        
        // When saving changes.
        testSetup.context.send(viewAction: .save)
        // Nothing to await right now,
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the changes should be applied.
        #expect(testSetup.roomProxy.applyPowerLevelChangesCalled)
        #expect(testSetup.roomProxy.applyPowerLevelChangesReceivedChanges == .init(roomAvatar: 0),
                "Only the avatar setting should be applied. No other settings were changed so they should be nil to remain left alone.")
    }
    
    @Test
    func saveNoChanges() {
        let testSetup = TestSetup(isSpace: false)
        // Given a screen with no changes.
        #expect(!testSetup.context.viewState.hasChanges)
        
        // When saving changes.
        testSetup.context.send(viewAction: .save)
        
        // Then nothing should happen.
        #expect(!testSetup.roomProxy.applyPowerLevelChangesCalled)
    }
    
    @Test
    func defaultStateRoom() {
        let testSetup = TestSetup(isSpace: false)
        #expect(testSetup.context.settings[.roomDetails] != nil)
        #expect(testSetup.context.settings[.memberModeration] != nil)
        #expect(testSetup.context.settings[.messagesAndContent] != nil)
        #expect(testSetup.context.settings[.manageSpace] == nil)
    }
    
    @Test
    func defaultStateSpace() {
        let testSetup = TestSetup(isSpace: true)
        #expect(testSetup.context.settings[.roomDetails] != nil)
        #expect(testSetup.context.settings[.memberModeration] != nil)
        #expect(testSetup.context.settings[.messagesAndContent] == nil)
        #expect(testSetup.context.settings[.manageSpace] != nil)
    }
}
