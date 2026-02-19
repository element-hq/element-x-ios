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
struct RoomChangeRolesScreenViewModelTests {
    var viewModel: RoomChangeRolesScreenViewModelProtocol!
    var roomProxy: JoinedRoomProxyMock!
    
    var context: RoomChangeRolesScreenViewModelType.Context {
        viewModel.context
    }
    
    @Test
    mutating func initialStateAdministrators() {
        setup(mode: .administrator)
        #expect(context.viewState.membersToPromote == [])
        #expect(context.viewState.membersToDemote == [])
        #expect(context.viewState.administrators == context.viewState.visibleAdministrators)
        #expect(context.viewState.moderators == context.viewState.visibleModerators)
        #expect(context.viewState.users == context.viewState.visibleUsers)
        #expect(context.viewState.membersWithRole.count == 2)
        #expect(context.viewState.membersWithRole.first?.id == RoomMemberProxyMock.mockAdmin.userID)
        #expect(!context.viewState.hasChanges)
        #expect(!context.viewState.isSearching)
    }
    
    @Test
    mutating func initialStateModerators() {
        setup(mode: .moderator)
        #expect(context.viewState.membersToPromote == [])
        #expect(context.viewState.membersToDemote == [])
        #expect(context.viewState.administrators == context.viewState.visibleAdministrators)
        #expect(context.viewState.moderators == context.viewState.visibleModerators)
        #expect(context.viewState.users == context.viewState.visibleUsers)
        #expect(context.viewState.membersWithRole.count == 3)
        #expect(context.viewState.membersWithRole.first { $0.id == RoomMemberProxyMock.mockModerator.userID } != nil)
        #expect(!context.viewState.hasChanges)
        #expect(!context.viewState.isSearching)
    }
    
    @Test
    mutating func toggleUserOn() throws {
        setup(mode: .moderator)
        let firstUser = try #require(context.viewState.users.first { !context.viewState.isMemberSelected($0) },
                                     "There should be a regular user available to promote.")
        
        context.send(viewAction: .toggleMember(firstUser))
        
        #expect(context.viewState.membersToPromote == [firstUser])
        #expect(context.viewState.membersToDemote == [])
        #expect(context.viewState.membersWithRole.count == 4)
        #expect(context.viewState.membersWithRole.contains(firstUser))
        #expect(context.viewState.hasChanges)
    }
    
    @Test
    mutating func toggleUserOff() throws {
        setup(mode: .moderator)
        let firstUser = try #require(context.viewState.users.first { !context.viewState.isMemberSelected($0) },
                                     "There should be a regular user available to promote.")
        
        // First toggle on
        context.send(viewAction: .toggleMember(firstUser))
        
        // Then toggle off
        context.send(viewAction: .toggleMember(firstUser))
        
        #expect(context.viewState.membersToPromote == [])
        #expect(context.viewState.membersToDemote == [])
        #expect(context.viewState.membersWithRole.count == 3)
        #expect(!context.viewState.membersWithRole.contains(firstUser))
        #expect(!context.viewState.hasChanges)
    }
    
    @Test
    mutating func demoteToggledUser() throws {
        setup(mode: .moderator)
        let firstUser = try #require(context.viewState.users.first { !context.viewState.isMemberSelected($0) },
                                     "There should be a regular user available to promote.")
        
        // First toggle on
        context.send(viewAction: .toggleMember(firstUser))
        
        // Then demote
        context.send(viewAction: .demoteMember(firstUser))
        
        #expect(context.viewState.membersToPromote == [])
        #expect(context.viewState.membersToDemote == [])
        #expect(context.viewState.membersWithRole.count == 3)
        #expect(!context.viewState.membersWithRole.contains(firstUser))
        #expect(!context.viewState.hasChanges)
    }
    
    @Test
    mutating func toggleModeratorOff() throws {
        setup(mode: .moderator)
        let existingModerator = try #require(context.viewState.membersWithRole.first { $0.role == .moderator },
                                             "There should be a member with the role before we begin.")
        
        context.send(viewAction: .toggleMember(existingModerator))
        
        #expect(context.viewState.membersToPromote == [])
        #expect(context.viewState.membersToDemote == [existingModerator])
        #expect(context.viewState.membersWithRole.count == 2)
        #expect(!context.viewState.membersWithRole.contains(existingModerator))
        #expect(context.viewState.hasChanges)
    }
    
    @Test
    mutating func toggleModeratorOn() throws {
        setup(mode: .moderator)
        let existingModerator = try #require(context.viewState.membersWithRole.first { $0.role == .moderator },
                                             "There should be a member with the role before we begin.")
        
        // First toggle off
        context.send(viewAction: .toggleMember(existingModerator))
        
        // Then toggle back on
        context.send(viewAction: .toggleMember(existingModerator))
        
        #expect(context.viewState.membersToPromote == [])
        #expect(context.viewState.membersToDemote == [])
        #expect(context.viewState.membersWithRole.count == 3)
        #expect(context.viewState.membersWithRole.contains(existingModerator))
        #expect(!context.viewState.hasChanges)
    }
    
    @Test
    mutating func demoteModerator() throws {
        setup(mode: .moderator)
        let existingModerator = try #require(context.viewState.membersWithRole.first { $0.role == .moderator },
                                             "There should be a member with the role before we begin.")
        
        context.send(viewAction: .demoteMember(existingModerator))
        
        #expect(context.viewState.membersToPromote == [])
        #expect(context.viewState.membersToDemote == [existingModerator])
        #expect(context.viewState.membersWithRole.count == 2)
        #expect(!context.viewState.membersWithRole.contains(existingModerator))
        #expect(context.viewState.hasChanges)
    }
    
    @Test
    mutating func saveModeratorChanges() async throws {
        // Given the change roles view model for moderators.
        setup(mode: .moderator)
        
        let firstUser = try #require(context.viewState.users.first { !context.viewState.isMemberSelected($0) },
                                     "There should be a regular user to begin with.")
        let existingModerator = try #require(context.viewState.membersWithRole.first { $0.role == .moderator },
                                             "There should be a moderator to begin with.")
        
        // When promoting a regular user and demoting a moderator.
        context.send(viewAction: .toggleMember(firstUser))
        context.send(viewAction: .toggleMember(existingModerator))
        context.send(viewAction: .save)
        
        try await Task.sleep(for: .milliseconds(100))
        
        // Then no warning should be shown, and the call to update the users should be made straight away.
        #expect(roomProxy.updatePowerLevelsForUsersCalled)
        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.count == 2)
        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains { $0.userID == existingModerator.id && $0.powerLevel == 0 } == true)
        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains { $0.userID == firstUser.id && $0.powerLevel == 50 } == true)
    }
    
    @Test
    mutating func savePromotedAdministrator() async throws {
        // Given the change roles view model for administrators.
        setup(mode: .administrator)
        #expect(context.alertInfo == nil)
        
        let firstUser = try #require(context.viewState.users.first { !context.viewState.isMemberSelected($0) },
                                     "There should be a regular user to begin with.")
        
        // When saving changes to promote a user to an administrator.
        context.send(viewAction: .toggleMember(firstUser))
        context.send(viewAction: .save)
        
        // Then an alert should be shown to warn the action cannot be undone.
        #expect(context.alertInfo != nil)
        
        // When confirming the prompt
        context.alertInfo?.primaryButton.action?()
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the user should be made into an administrator.
        #expect(roomProxy.updatePowerLevelsForUsersCalled)
        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.count == 1)
        #expect(roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains { $0.userID == firstUser.id && $0.powerLevel == 100 } == true)
    }
    
    // MARK: - Helpers
    
    private mutating func setup(mode: RoomRole) {
        roomProxy = JoinedRoomProxyMock(.init(members: .allMembersAsAdmin))
        viewModel = RoomChangeRolesScreenViewModel(mode: mode,
                                                   roomProxy: roomProxy,
                                                   mediaProvider: MediaProviderMock(configuration: .init()),
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   analytics: ServiceLocator.shared.analytics)
    }
}
