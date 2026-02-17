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
    @MainActor
    private struct TestSetup {
        var viewModel: RoomChangeRolesScreenViewModelProtocol
        var roomProxy: JoinedRoomProxyMock
        
        var context: RoomChangeRolesScreenViewModelType.Context {
            viewModel.context
        }
        
        init(mode: RoomRole) {
            roomProxy = JoinedRoomProxyMock(.init(members: .allMembersAsAdmin))
            viewModel = RoomChangeRolesScreenViewModel(mode: mode,
                                                       roomProxy: roomProxy,
                                                       mediaProvider: MediaProviderMock(configuration: .init()),
                                                       userIndicatorController: UserIndicatorControllerMock(),
                                                       analytics: ServiceLocator.shared.analytics)
        }
    }
    
    @Test
    func initialStateAdministrators() {
        let testSetup = TestSetup(mode: .administrator)
        #expect(testSetup.context.viewState.membersToPromote == [])
        #expect(testSetup.context.viewState.membersToDemote == [])
        #expect(testSetup.context.viewState.administrators == testSetup.context.viewState.visibleAdministrators)
        #expect(testSetup.context.viewState.moderators == testSetup.context.viewState.visibleModerators)
        #expect(testSetup.context.viewState.users == testSetup.context.viewState.visibleUsers)
        #expect(testSetup.context.viewState.membersWithRole.count == 2)
        #expect(testSetup.context.viewState.membersWithRole.first?.id == RoomMemberProxyMock.mockAdmin.userID)
        #expect(!testSetup.context.viewState.hasChanges)
        #expect(!testSetup.context.viewState.isSearching)
    }
    
    @Test
    func initialStateModerators() {
        let testSetup = TestSetup(mode: .moderator)
        #expect(testSetup.context.viewState.membersToPromote == [])
        #expect(testSetup.context.viewState.membersToDemote == [])
        #expect(testSetup.context.viewState.administrators == testSetup.context.viewState.visibleAdministrators)
        #expect(testSetup.context.viewState.moderators == testSetup.context.viewState.visibleModerators)
        #expect(testSetup.context.viewState.users == testSetup.context.viewState.visibleUsers)
        #expect(testSetup.context.viewState.membersWithRole.count == 3)
        #expect(testSetup.context.viewState.membersWithRole.first { $0.id == RoomMemberProxyMock.mockModerator.userID } != nil)
        #expect(!testSetup.context.viewState.hasChanges)
        #expect(!testSetup.context.viewState.isSearching)
    }
    
    @Test
    func toggleUserOn() throws {
        let testSetup = TestSetup(mode: .moderator)
        let firstUser = try #require(testSetup.context.viewState.users.first { !testSetup.context.viewState.isMemberSelected($0) },
                                     "There should be a regular user available to promote.")
        
        testSetup.context.send(viewAction: .toggleMember(firstUser))
        
        #expect(testSetup.context.viewState.membersToPromote == [firstUser])
        #expect(testSetup.context.viewState.membersToDemote == [])
        #expect(testSetup.context.viewState.membersWithRole.count == 4)
        #expect(testSetup.context.viewState.membersWithRole.contains(firstUser))
        #expect(testSetup.context.viewState.hasChanges)
    }
    
    @Test
    func toggleUserOff() throws {
        let testSetup = TestSetup(mode: .moderator)
        let firstUser = try #require(testSetup.context.viewState.users.first { !testSetup.context.viewState.isMemberSelected($0) },
                                     "There should be a regular user available to promote.")
        
        // First toggle on
        testSetup.context.send(viewAction: .toggleMember(firstUser))
        
        // Then toggle off
        testSetup.context.send(viewAction: .toggleMember(firstUser))
        
        #expect(testSetup.context.viewState.membersToPromote == [])
        #expect(testSetup.context.viewState.membersToDemote == [])
        #expect(testSetup.context.viewState.membersWithRole.count == 3)
        #expect(!testSetup.context.viewState.membersWithRole.contains(firstUser))
        #expect(!testSetup.context.viewState.hasChanges)
    }
    
    @Test
    func demoteToggledUser() throws {
        let testSetup = TestSetup(mode: .moderator)
        let firstUser = try #require(testSetup.context.viewState.users.first { !testSetup.context.viewState.isMemberSelected($0) },
                                     "There should be a regular user available to promote.")
        
        // First toggle on
        testSetup.context.send(viewAction: .toggleMember(firstUser))
        
        // Then demote
        testSetup.context.send(viewAction: .demoteMember(firstUser))
        
        #expect(testSetup.context.viewState.membersToPromote == [])
        #expect(testSetup.context.viewState.membersToDemote == [])
        #expect(testSetup.context.viewState.membersWithRole.count == 3)
        #expect(!testSetup.context.viewState.membersWithRole.contains(firstUser))
        #expect(!testSetup.context.viewState.hasChanges)
    }
    
    @Test
    func toggleModeratorOff() throws {
        let testSetup = TestSetup(mode: .moderator)
        let existingModerator = try #require(testSetup.context.viewState.membersWithRole.first { $0.role == .moderator },
                                             "There should be a member with the role before we begin.")
        
        testSetup.context.send(viewAction: .toggleMember(existingModerator))
        
        #expect(testSetup.context.viewState.membersToPromote == [])
        #expect(testSetup.context.viewState.membersToDemote == [existingModerator])
        #expect(testSetup.context.viewState.membersWithRole.count == 2)
        #expect(!testSetup.context.viewState.membersWithRole.contains(existingModerator))
        #expect(testSetup.context.viewState.hasChanges)
    }
    
    @Test
    func toggleModeratorOn() throws {
        let testSetup = TestSetup(mode: .moderator)
        let existingModerator = try #require(testSetup.context.viewState.membersWithRole.first { $0.role == .moderator },
                                             "There should be a member with the role before we begin.")
        
        // First toggle off
        testSetup.context.send(viewAction: .toggleMember(existingModerator))
        
        // Then toggle back on
        testSetup.context.send(viewAction: .toggleMember(existingModerator))
        
        #expect(testSetup.context.viewState.membersToPromote == [])
        #expect(testSetup.context.viewState.membersToDemote == [])
        #expect(testSetup.context.viewState.membersWithRole.count == 3)
        #expect(testSetup.context.viewState.membersWithRole.contains(existingModerator))
        #expect(!testSetup.context.viewState.hasChanges)
    }
    
    @Test
    func demoteModerator() throws {
        let testSetup = TestSetup(mode: .moderator)
        let existingModerator = try #require(testSetup.context.viewState.membersWithRole.first { $0.role == .moderator },
                                             "There should be a member with the role before we begin.")
        
        testSetup.context.send(viewAction: .demoteMember(existingModerator))
        
        #expect(testSetup.context.viewState.membersToPromote == [])
        #expect(testSetup.context.viewState.membersToDemote == [existingModerator])
        #expect(testSetup.context.viewState.membersWithRole.count == 2)
        #expect(!testSetup.context.viewState.membersWithRole.contains(existingModerator))
        #expect(testSetup.context.viewState.hasChanges)
    }
    
    @Test
    func saveModeratorChanges() async throws {
        // Given the change roles view model for moderators.
        let testSetup = TestSetup(mode: .moderator)
        
        let firstUser = try #require(testSetup.context.viewState.users.first { !testSetup.context.viewState.isMemberSelected($0) },
                                     "There should be a regular user to begin with.")
        let existingModerator = try #require(testSetup.context.viewState.membersWithRole.first { $0.role == .moderator },
                                             "There should be a moderator to begin with.")
        
        // When promoting a regular user and demoting a moderator.
        testSetup.context.send(viewAction: .toggleMember(firstUser))
        testSetup.context.send(viewAction: .toggleMember(existingModerator))
        testSetup.context.send(viewAction: .save)
        
        try await Task.sleep(for: .milliseconds(100))
        
        // Then no warning should be shown, and the call to update the users should be made straight away.
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersCalled)
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersReceivedUpdates?.count == 2)
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains { $0.userID == existingModerator.id && $0.powerLevel == 0 } == true)
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains { $0.userID == firstUser.id && $0.powerLevel == 50 } == true)
    }
    
    @Test
    func savePromotedAdministrator() async throws {
        // Given the change roles view model for administrators.
        let testSetup = TestSetup(mode: .administrator)
        #expect(testSetup.context.alertInfo == nil)
        
        let firstUser = try #require(testSetup.context.viewState.users.first { !testSetup.context.viewState.isMemberSelected($0) },
                                     "There should be a regular user to begin with.")
        
        // When saving changes to promote a user to an administrator.
        testSetup.context.send(viewAction: .toggleMember(firstUser))
        testSetup.context.send(viewAction: .save)
        
        // Then an alert should be shown to warn the action cannot be undone.
        #expect(testSetup.context.alertInfo != nil)
        
        // When confirming the prompt
        testSetup.context.alertInfo?.primaryButton.action?()
        try await Task.sleep(for: .milliseconds(100))
        
        // Then the user should be made into an administrator.
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersCalled)
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersReceivedUpdates?.count == 1)
        #expect(testSetup.roomProxy.updatePowerLevelsForUsersReceivedUpdates?.contains { $0.userID == firstUser.id && $0.powerLevel == 100 } == true)
    }
}
