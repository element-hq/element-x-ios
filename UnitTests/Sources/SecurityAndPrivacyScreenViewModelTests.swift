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
import Testing

@Suite
@MainActor
final class SecurityAndPrivacyScreenViewModelTests {
    var viewModel: SecurityAndPrivacyScreenViewModelProtocol!
    var spaceServiceProxy: SpaceServiceProxyMock!
    var roomProxy: JoinedRoomProxyMock!
    
    var context: SecurityAndPrivacyScreenViewModelType.Context {
        viewModel.context
    }
    
    deinit {
        viewModel = nil
        roomProxy = nil
        AppSettings.resetAllSettings()
    }
    
    @Test
    func setSingleJoinedSpaceMembersAccess() async throws {
        let singleRoom = [SpaceServiceRoom].mockSingleRoom
        let space = singleRoom[0]
        setupViewModel(joinedParentSpaces: singleRoom, joinRule: .public)
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableJoinedSpaces.count == 1 }
        try await deferred.fulfill()
        
        #expect(context.viewState.currentSettings.accessType == .anyone)
        #expect(context.viewState.isSaveDisabled)
        #expect(context.viewState.isSpaceMembersOptionSelectable)
        guard case .singleJoined = context.viewState.spaceSelection else {
            Issue.record("Expected spaceSelection to be .singleJoined")
            return
        }
        
        context.send(viewAction: .selectedSpaceMembersAccess)
        #expect(context.desiredSettings.accessType == .spaceMembers(spaceIDs: [space.id]))
        #expect(!context.viewState.shouldShowAccessSectionFooter)
        #expect(!context.viewState.isSaveDisabled)
        
        await waitForConfirmation("Join rule has updated") { confirm in
            roomProxy.updateJoinRuleClosure = { value in
                #expect(value == .restricted(rules: [.roomMembership(roomID: space.id)]))
                confirm()
                return .success(())
            }
            context.send(viewAction: .save)
        }
    }
    
    @Test
    func setSingleJoinedAskToJoinWithSpaceMembersAccess() async throws {
        let singleRoom = [SpaceServiceRoom].mockSingleRoom
        let space = singleRoom[0]
        setupViewModel(joinedParentSpaces: singleRoom, joinRule: .public)
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableJoinedSpaces.count == 1 }
        try await deferred.fulfill()
        
        #expect(context.viewState.currentSettings.accessType == .anyone)
        #expect(context.viewState.isSaveDisabled)
        #expect(context.viewState.isAskToJoinWithSpaceMembersOptionSelectable)
        guard case .singleJoined = context.viewState.spaceSelection else {
            Issue.record("Expected spaceSelection to be .singleJoined")
            return
        }
        
        context.send(viewAction: .selectedAskToJoinWithSpaceMembersAccess)
        #expect(context.desiredSettings.accessType == .askToJoinWithSpaceMembers(spaceIDs: [space.id]))
        #expect(!context.viewState.shouldShowAccessSectionFooter)
        #expect(!context.viewState.isSaveDisabled)
        
        await waitForConfirmation("Join rule has updated") { confirm in
            roomProxy.updateJoinRuleClosure = { value in
                #expect(value == .knockRestricted(rules: [.roomMembership(roomID: space.id)]))
                confirm()
                return .success(())
            }
            context.send(viewAction: .save)
        }
    }
    
    @Test
    func singleUnknownSpaceMembersAccessCanBeReselected() async throws {
        let singleRoom = [SpaceServiceRoom].mockSingleRoom
        let space = singleRoom[0]
        setupViewModel(joinedParentSpaces: [], joinRule: .restricted(rules: [.roomMembership(roomID: space.id)]))
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableJoinedSpaces.count == 0 }
        try await deferred.fulfill()
        
        #expect(context.viewState.currentSettings.accessType == .spaceMembers(spaceIDs: [space.id]))
        #expect(context.desiredSettings == context.viewState.currentSettings)
        #expect(context.viewState.isSpaceMembersOptionSelectable)
        #expect(!context.viewState.shouldShowAccessSectionFooter)
        #expect(context.viewState.isSaveDisabled)
        guard case .singleUnknown = context.viewState.spaceSelection else {
            Issue.record("Expected spaceSelection to be .singleUnknown")
            return
        }
        
        context.desiredSettings.accessType = .anyone
        #expect(context.viewState.isSpaceMembersOptionSelectable)
        #expect(!context.viewState.isSaveDisabled)
        
        context.send(viewAction: .selectedSpaceMembersAccess)
        #expect(context.viewState.isSaveDisabled)
        #expect(context.desiredSettings.accessType == .spaceMembers(spaceIDs: [space.id]))
        guard case .singleUnknown = context.viewState.spaceSelection else {
            Issue.record("Expected spaceSelection to be .singleUnknown")
            return
        }
    }
    
    @Test
    func multipleKnownSpacesMembersSelection() async throws {
        let spaces = [SpaceServiceRoom].mockJoinedSpaces2
        setupViewModel(joinedParentSpaces: spaces, joinRule: .public)
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableJoinedSpaces.count == 3 }
        try await deferred.fulfill()
        
        #expect(context.viewState.currentSettings.accessType == .anyone)
        #expect(context.viewState.isSaveDisabled)
        #expect(context.viewState.isSpaceMembersOptionSelectable)
        guard case .multiple = context.viewState.spaceSelection else {
            Issue.record("Expected spaceSelection to be .multiple")
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
        #expect(context.desiredSettings.accessType == .spaceMembers(spaceIDs: [spaces[0].id]))
        #expect(context.viewState.shouldShowAccessSectionFooter)
        #expect(!context.viewState.isSaveDisabled)

        await waitForConfirmation("Join rule has updated") { confirm in
            roomProxy.updateJoinRuleClosure = { value in
                #expect(value == .restricted(rules: [.roomMembership(roomID: spaces[0].id)]))
                confirm()
                return .success(())
            }
            context.send(viewAction: .save)
        }
    }
    
    @Test
    func multipleKnownAskToJoinSpacesMembersSelection() async throws {
        let spaces = [SpaceServiceRoom].mockJoinedSpaces2
        setupViewModel(joinedParentSpaces: spaces, joinRule: .public)
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableJoinedSpaces.count == 3 }
        try await deferred.fulfill()
        
        #expect(context.viewState.currentSettings.accessType == .anyone)
        #expect(context.viewState.isSaveDisabled)
        #expect(context.viewState.isAskToJoinWithSpaceMembersOptionSelectable)
        guard case .multiple = context.viewState.spaceSelection else {
            Issue.record("Expected spaceSelection to be .multiple")
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
        #expect(context.desiredSettings.accessType == .askToJoinWithSpaceMembers(spaceIDs: [spaces[0].id]))
        #expect(context.viewState.shouldShowAccessSectionFooter)
        #expect(!context.viewState.isSaveDisabled)

        await waitForConfirmation("Join rule has updated") { confirm in
            roomProxy.updateJoinRuleClosure = { value in
                #expect(value == .knockRestricted(rules: [.roomMembership(roomID: spaces[0].id)]))
                confirm()
                return .success(())
            }
            context.send(viewAction: .save)
        }
    }
    
    @Test
    func multipleSpacesMembersSelection() async throws {
        let spaces = [SpaceServiceRoom].mockJoinedSpaces2
        setupViewModel(joinedParentSpaces: spaces,
                       joinRule: .restricted(rules: [.roomMembership(roomID: "unknownSpaceID")]))
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableSpacesCount == 4 }
        try await deferred.fulfill()
        
        #expect(context.viewState.currentSettings.accessType.isSpaceMembers)
        #expect(context.viewState.isSaveDisabled)
        #expect(context.viewState.isSpaceMembersOptionSelectable)
        guard case .multiple = context.viewState.spaceSelection else {
            Issue.record("Expected spaceSelection to be .multiple")
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
        #expect(context.desiredSettings.accessType == .spaceMembers(spaceIDs: [spaces[0].id, "unknownSpaceID"]))
        #expect(context.viewState.shouldShowAccessSectionFooter)
        #expect(!context.viewState.isSaveDisabled)

        await waitForConfirmation("Join rule has updated") { confirm in
            roomProxy.updateJoinRuleClosure = { value in
                #expect(value == .restricted(rules: [.roomMembership(roomID: spaces[0].id), .roomMembership(roomID: "unknownSpaceID")]))
                confirm()
                return .success(())
            }
            context.send(viewAction: .save)
        }
    }
    
    @Test
    func multipleSpacesMembersSelectionWithAnExistingNonParentButJoinedSpace() async throws {
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
        
        #expect(context.viewState.currentSettings.accessType.isSpaceMembers)
        #expect(context.viewState.isSaveDisabled)
        #expect(context.viewState.isSpaceMembersOptionSelectable)
        guard case .multiple = context.viewState.spaceSelection else {
            Issue.record("Expected spaceSelection to be .multiple")
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
        #expect(context.desiredSettings.accessType == .spaceMembers(spaceIDs: [allSpaces[0].id, "unknownSpaceID"]))
        #expect(context.viewState.shouldShowAccessSectionFooter)
        #expect(!context.viewState.isSaveDisabled)
    }
    
    @Test
    func emptySpaceMembersSelectionEdgeCase() async throws {
        // Edge case where there is no available joined parents and the room has a restricted join rule.
        // With no space ids in it
        setupViewModel(joinedParentSpaces: [],
                       joinRule: .restricted(rules: []))
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableSpacesCount == 0 }
        try await deferred.fulfill()
        
        #expect(context.viewState.currentSettings.accessType.isSpaceMembers)
        #expect(context.viewState.isSaveDisabled)
        #expect(!context.viewState.isSpaceMembersOptionSelectable)
        #expect(!context.viewState.shouldShowAccessSectionFooter)
        guard case .empty = context.viewState.spaceSelection else {
            Issue.record("Expected spaceSelection to be .empty")
            return
        }
    }
    
    @Test
    func emptySpaceMembersSelectionWithJoinedParentEdgeCase() async throws {
        // Edge case where there is one available joined parent but the room has a restricted join rule.
        // With no space ids in it
        let singleRoom = [SpaceServiceRoom].mockSingleRoom
        setupViewModel(joinedParentSpaces: singleRoom,
                       joinRule: .restricted(rules: []))
        
        let deferred = deferFulfillment(context.$viewState) { $0.selectableSpacesCount == 1 }
        try await deferred.fulfill()
        
        #expect(context.viewState.currentSettings.accessType.isSpaceMembers)
        #expect(context.viewState.isSaveDisabled)
        #expect(context.viewState.isSpaceMembersOptionSelectable)
        #expect(context.viewState.shouldShowAccessSectionFooter)
        guard case .multiple = context.viewState.spaceSelection else {
            Issue.record("Expected spaceSelection to be .multiple")
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
    
    @Test
    func save() async throws {
        setupViewModel(joinedParentSpaces: [], joinRule: .public)
        
        // Saving shouldn't dismiss this screen (or trigger any other action).
        let deferred = deferFailure(viewModel.actionsPublisher, timeout: .seconds(1)) { _ in true }
        
        context.desiredSettings.accessType = .inviteOnly
        context.send(viewAction: .save)
        
        try await deferred.fulfill()
    }
    
    @Test
    func cancelWithChangesAndDiscard() async throws {
        setupViewModel(joinedParentSpaces: [], joinRule: .public)
        context.desiredSettings.accessType = .inviteOnly
        #expect(!context.viewState.isSaveDisabled)
        #expect(context.alertInfo == nil)
        
        context.send(viewAction: .cancel)
        
        #expect(context.alertInfo != nil)
        
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
    
    @Test
    func cancelWithChangesAndSave() async throws {
        setupViewModel(joinedParentSpaces: [], joinRule: .public)
        context.desiredSettings.accessType = .inviteOnly
        #expect(!context.viewState.isSaveDisabled)
        #expect(context.alertInfo == nil)
        
        context.send(viewAction: .cancel)
        
        #expect(context.alertInfo != nil)
        
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
    
    @Test
    func cancelWithChangesAndSaveWithFailure() async throws {
        setupViewModel(joinedParentSpaces: [], joinRule: .public)
        roomProxy.updateJoinRuleReturnValue = .failure(.sdkError(RoomProxyMockError.generic))
        context.desiredSettings.accessType = .inviteOnly
        #expect(!context.viewState.isSaveDisabled)
        #expect(context.alertInfo == nil)
        
        context.send(viewAction: .cancel)
        
        #expect(context.alertInfo != nil)
        
        // The screen should not be dismissed if a failure occurred.
        let deferred = deferFailure(viewModel.actionsPublisher, timeout: .seconds(1)) { _ in true }
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
