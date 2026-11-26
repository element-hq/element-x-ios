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
struct UserProfileScreenViewModelTests {
    @Test("Another user's profile loads with a permalink")
    func initialState() async throws {
        let userIndicatorController = UserIndicatorControllerMock()
        
        let profile = UserProfile(userID: "@alice:matrix.org", displayName: "Alice", avatarURL: .mockMXCAvatar)
        let clientProxy = ClientProxyMock(.init())
        clientProxy.profileForReturnValue = .success(profile)
        
        let viewModel = UserProfileScreenViewModel(userID: profile.id,
                                                   isPresentedModally: false,
                                                   userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                   analytics: AnalyticsServiceMock(.init()),
                                                   userIndicatorController: userIndicatorController)
        let context = viewModel.context
        
        let waitForMemberToLoad = deferFulfillment(context.observe(\.viewState.userProfile)) { $0 != nil }
        try await waitForMemberToLoad.fulfill()
        
        #expect(!context.viewState.isOwnUser)
        #expect(context.viewState.userProfile == profile)
        #expect(context.viewState.permalink != nil)
    }
    
    @Test("The account owner's profile loads and is marked as their own")
    func initialStateAccountOwner() async throws {
        let userIndicatorController = UserIndicatorControllerMock()
        
        let profile = UserProfile(userID: RoomMemberProxyMock.mockMe.userID, displayName: "Me", avatarURL: .mockMXCAvatar)
        let clientProxy = ClientProxyMock(.init())
        clientProxy.profileForReturnValue = .success(profile)
        
        let viewModel = UserProfileScreenViewModel(userID: profile.id,
                                                   isPresentedModally: false,
                                                   userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                   analytics: AnalyticsServiceMock(.init()),
                                                   userIndicatorController: userIndicatorController)
        let context = viewModel.context
        
        let waitForMemberToLoad = deferFulfillment(context.observe(\.viewState.userProfile)) { $0 != nil }
        try await waitForMemberToLoad.fulfill()
        
        #expect(context.viewState.isOwnUser)
        #expect(context.viewState.userProfile == profile)
        #expect(context.viewState.permalink != nil)
    }
    
    @Test("Starting a direct chat with a user without a known identity asks to confirm the invite")
    func startingDMWithUnknownUser() async throws {
        let userIndicatorController = UserIndicatorControllerMock()
        
        let profile = UserProfile.mockAlice
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.directRoomForUserIDReturnValue = .success(nil)
        clientProxy.userIdentityForFallBackToServerReturnValue = .success(nil)
        
        let viewModel = UserProfileScreenViewModel(userID: profile.id,
                                                   isPresentedModally: false,
                                                   userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                   analytics: AnalyticsServiceMock(.init()),
                                                   userIndicatorController: userIndicatorController)
        
        let context = viewModel.context
        
        let waitForMemberToLoad = deferFulfillment(context.observe(\.viewState.userProfile)) { $0 != nil }
        try await waitForMemberToLoad.fulfill()
        
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.inviteConfirmationUser), timeout: .seconds(5)) { $0?.isUnknown == true }
        
        context.send(viewAction: .openDirectChat)
        try await deferred.fulfill()
    }
    
    @Test("Stopping the screen closes its open avatar preview at once")
    func stop() async throws {
        let viewModel = UserProfileScreenViewModel(userID: UserProfile.mockAlice.id,
                                                   isPresentedModally: false,
                                                   userSession: UserSessionMock(.init()),
                                                   analytics: AnalyticsServiceMock(.init()),
                                                   userIndicatorController: UserIndicatorControllerMock())
        let mediaPreviewItem = MediaPreviewItem(file: .unmanaged(url: .mockMXCAvatar), title: "Alice")
        viewModel.context.mediaPreviewItem = mediaPreviewItem
        
        let deferred = deferFulfillment(mediaPreviewItem.immediateDismissalPublisher) { _ in true }
        viewModel.stop()
        try await deferred.fulfill()
        
        #expect(viewModel.context.mediaPreviewItem == nil)
    }
}
