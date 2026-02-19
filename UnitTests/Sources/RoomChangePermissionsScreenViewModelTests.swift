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
    var roomProxy: JoinedRoomProxyMock!
    var viewModel: RoomChangePermissionsScreenViewModelProtocol!
    
    var context: RoomChangePermissionsScreenViewModelType.Context {
        viewModel.context
    }

    @Test
    mutating func changeSetting() throws {
        setup(isSpace: false)
        // Given a screen with no changes.
        let index = try #require(context.settings[.roomDetails]?.firstIndex { $0.keyPath == \.roomAvatar },
                                 "There should be a setting for the room avatar.")
        #expect(context.settings[.roomDetails]?[index].roleValue == .moderator)
        #expect(!context.viewState.hasChanges)
        
        // When updating a setting.
        let setting = RoomPermissionsSetting(title: "",
                                             value: RoomRole.user.powerLevelValue,
                                             ownPowerLevel: RoomRole.creator.powerLevel,
                                             keyPath: \.roomAvatar)
        #expect(!setting.isDisabled)
        #expect(setting.availableValues.map(\.tag) == RoomPermissionsSetting.allValues.map(\.tag))
        context.settings[.roomDetails]?[index] = setting
        
        // Then the setting should update and the changes should be flagged.
        #expect(context.settings[.roomDetails]?[index].roleValue == .user)
        #expect(context.viewState.hasChanges)
    }
    
    @Test
    mutating func settingsCantBeChanged() throws {
        setup(isSpace: false, ownPowerLevel: .value(25))
        // Given a screen with no changes.
        var index = try #require(context.settings[.roomDetails]?.firstIndex { $0.keyPath == \.roomAvatar },
                                 "There should be a setting for the room avatar.")
        #expect(context.settings[.roomDetails]?[index].roleValue == .moderator)
        #expect(context.settings[.roomDetails]?[index].isDisabled == true)
        #expect(context.settings[.roomDetails]?[index].availableValues.count == 1)
        #expect(!context.viewState.hasChanges)
        
        index = try #require(context.settings[.messagesAndContent]?.firstIndex { $0.keyPath == \.eventsDefault },
                             "There should be a setting for the events.")
        #expect(context.settings[.messagesAndContent]?[index].roleValue == .user)
        #expect(context.settings[.messagesAndContent]?[index].isDisabled == false)
        #expect(context.settings[.messagesAndContent]?[index].availableValues.count == 1)
    }
    
    @Test
    mutating func save() async throws {
        setup(isSpace: false)
        // Given a screen with changes.
        let index = try #require(context.settings[.roomDetails]?.firstIndex { $0.keyPath == \.roomAvatar },
                                 "There should be a setting for the room avatar.")
        context.settings[.roomDetails]?[index] = RoomPermissionsSetting(title: "",
                                                                        value: RoomRole.user.powerLevelValue,
                                                                        ownPowerLevel: RoomRole.creator.powerLevel,
                                                                        keyPath: \.roomAvatar)
        #expect(context.settings[.roomDetails]?[index].roleValue == .user)
        #expect(context.settings[.roomDetails]?[index].isDisabled == false)
        #expect(context.settings[.roomDetails]?[index].availableValues.map(\.tag) == RoomPermissionsSetting.allValues.map(\.tag))
        #expect(context.viewState.hasChanges)
        #expect(context.settings.count == 3)
        
        // When saving changes.
        context.send(viewAction: .save)
        // Nothing to await right now,
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the changes should be applied.
        #expect(roomProxy.applyPowerLevelChangesCalled)
        #expect(roomProxy.applyPowerLevelChangesReceivedChanges == .init(roomAvatar: 0),
                "Only the avatar setting should be applied. No other settings were changed so they should be nil to remain left alone.")
    }
    
    @Test
    mutating func saveNoChanges() {
        setup(isSpace: false)
        // Given a screen with no changes.
        #expect(!context.viewState.hasChanges)
        
        // When saving changes.
        context.send(viewAction: .save)
        
        // Then nothing should happen.
        #expect(!roomProxy.applyPowerLevelChangesCalled)
    }
    
    @Test
    mutating func defaultStateRoom() {
        setup(isSpace: false)
        #expect(context.settings[.roomDetails] != nil)
        #expect(context.settings[.memberModeration] != nil)
        #expect(context.settings[.messagesAndContent] != nil)
        #expect(context.settings[.manageSpace] == nil)
    }
    
    @Test
    mutating func defaultStateSpace() {
        setup(isSpace: true)
        #expect(context.settings[.roomDetails] != nil)
        #expect(context.settings[.memberModeration] != nil)
        #expect(context.settings[.messagesAndContent] == nil)
        #expect(context.settings[.manageSpace] != nil)
    }
    
    // MARK: - Helpers
    
    private mutating func setup(isSpace: Bool, ownPowerLevel: RoomPowerLevel = RoomRole.creator.powerLevel) {
        roomProxy = JoinedRoomProxyMock(.init(isSpace: isSpace))
        viewModel = RoomChangePermissionsScreenViewModel(currentPermissions: .init(powerLevels: .mock),
                                                         ownPowerLevel: ownPowerLevel,
                                                         roomProxy: roomProxy,
                                                         userIndicatorController: UserIndicatorControllerMock(),
                                                         analytics: ServiceLocator.shared.analytics)
    }
}
