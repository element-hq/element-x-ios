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
    @Test
    func initialState() async throws {
        let profile = UserProfileProxy(userID: "@alice:matrix.org", displayName: "Alice", avatarURL: .mockMXCAvatar)
        let clientProxy = ClientProxyMock(.init())
        clientProxy.profileForReturnValue = .success(profile)
        
        let viewModel = UserProfileScreenViewModel(userID: profile.userID,
                                                   isPresentedModally: false,
                                                   userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                   analytics: ServiceLocator.shared.analytics,
                                                   appSettings: ServiceLocator.shared.settings)
        let context = viewModel.context
        
        let waitForMemberToLoad = deferFulfillment(context.observe(\.viewState.userProfile)) { $0 != nil }
        try await waitForMemberToLoad.fulfill()
        
        #expect(!context.viewState.isOwnUser)
        #expect(context.viewState.userProfile == profile)
        #expect(context.viewState.permalink != nil)
    }
    
    @Test
    func initialStateAccountOwner() async throws {
        let profile = UserProfileProxy(userID: RoomMemberProxyMock.mockMe.userID, displayName: "Me", avatarURL: .mockMXCAvatar)
        let clientProxy = ClientProxyMock(.init())
        clientProxy.profileForReturnValue = .success(profile)
        
        let viewModel = UserProfileScreenViewModel(userID: profile.userID,
                                                   isPresentedModally: false,
                                                   userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                   analytics: ServiceLocator.shared.analytics,
                                                   appSettings: ServiceLocator.shared.settings)
        let context = viewModel.context
        
        let waitForMemberToLoad = deferFulfillment(context.observe(\.viewState.userProfile)) { $0 != nil }
        try await waitForMemberToLoad.fulfill()
        
        #expect(context.viewState.isOwnUser)
        #expect(context.viewState.userProfile == profile)
        #expect(context.viewState.permalink != nil)
    }
    
    @Test
    func startingDmWithUnknownUserFetchesIdentity() async throws {
        ServiceLocator.shared.settings.enableKeyShareOnInvite = true
        
        let profile = UserProfileProxy.mockAlice
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.directRoomForUserIDReturnValue = .success(nil)
        clientProxy.userIdentityForFallBackToServerReturnValue = .success(nil)
        
        let viewModel = UserProfileScreenViewModel(userID: profile.userID,
                                                   isPresentedModally: false,
                                                   userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                   analytics: ServiceLocator.shared.analytics,
                                                   appSettings: ServiceLocator.shared.settings)
        
        let context = viewModel.context
        
        let waitForMemberToLoad = deferFulfillment(context.observe(\.viewState.userProfile)) { $0 != nil }
        try await waitForMemberToLoad.fulfill()
        
        let deferred = deferFulfillment(context.observe(\.viewState.bindings).compactMap(\.inviteConfirmationUser), timeout: .seconds(5)) { $0.isUnknown }

        context.send(viewAction: .openDirectChat)
        try await deferred.fulfill()
    }
}
