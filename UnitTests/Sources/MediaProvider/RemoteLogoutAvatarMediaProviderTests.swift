//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import SwiftUI
import Testing

@MainActor
struct RemoteLogoutAvatarMediaProviderTests {
    private let avatarSource: MediaSourceProxy
    private let clientProxy: ClientProxyMock
    private let mediaLoader = MediaLoaderMock()
    
    init() throws {
        let avatarURL: URL = "mxc://matrix.org/avatar"
        avatarSource = try MediaSourceProxy(url: avatarURL, mimeType: nil)
        clientProxy = ClientProxyMock(.init(userID: "@alice:matrix.org"))
        clientProxy.userProfilePublisher = .init(UserProfile(userID: "@alice:matrix.org", avatarURL: avatarURL))
        clientProxy.mediaLoader = mediaLoader
    }
    
    @Test("The avatar is loaded at the account info card's size when that's cached")
    func accountInfoCardSize() async throws {
        // Given an avatar that's cached at every size.
        let imageData = try makeImageData()
        mediaLoader.loadCachedMediaThumbnailForSourceWidthHeightClosure = { _, _, _ in imageData }
        
        // When creating the media provider.
        let mediaProvider = await RemoteLogoutAvatarMediaProvider(remoteLogoutClientProxy: clientProxy)
        
        // Then the avatar is only loaded from the cache at the account info card's size.
        #expect(mediaLoader.loadCachedMediaThumbnailForSourceWidthHeightReceivedInvocations.map(\.width) == [width(on: .accountInfoCard)])
        #expect(!mediaLoader.loadMediaThumbnailForSourceWidthHeightCalled)
        #expect(mediaProvider.imageFromSource(avatarSource, size: nil) != nil)
    }
    
    @Test("The chats size is tried when the account info card's isn't cached")
    func fallbackSize() async throws {
        // Given an avatar that's only cached at the chats size.
        let imageData = try makeImageData()
        let chatsWidth = width(on: .chats)
        mediaLoader.loadCachedMediaThumbnailForSourceWidthHeightClosure = { _, width, _ in
            width == chatsWidth ? imageData : nil
        }
        
        // When creating the media provider.
        let mediaProvider = await RemoteLogoutAvatarMediaProvider(remoteLogoutClientProxy: clientProxy)
        
        // Then the account info card's size is tried before the chats size, which provides the avatar.
        #expect(mediaLoader.loadCachedMediaThumbnailForSourceWidthHeightReceivedInvocations.map(\.width) == [width(on: .accountInfoCard), chatsWidth])
        #expect(!mediaLoader.loadMediaThumbnailForSourceWidthHeightCalled)
        #expect(mediaProvider.imageFromSource(avatarSource, size: nil) != nil)
    }
    
    @Test("Nothing is provided when the avatar isn't cached at any of the sizes")
    func uncachedAvatar() async throws {
        // Given an avatar that isn't cached.
        mediaLoader.loadCachedMediaThumbnailForSourceWidthHeightClosure = { _, _, _ in nil }
        
        // When creating the media provider.
        let mediaProvider = await RemoteLogoutAvatarMediaProvider(remoteLogoutClientProxy: clientProxy)
        
        // Then nothing is provided, without falling back to the network.
        #expect(!mediaLoader.loadMediaThumbnailForSourceWidthHeightCalled)
        #expect(mediaProvider.imageFromSource(avatarSource, size: nil) == nil)
        await #expect(throws: MediaProviderError.self) {
            try await mediaProvider.loadImageRetryingOnReconnection(avatarSource).value
        }
    }
    
    @Test("Only the account's own avatar is provided")
    func otherMedia() async throws {
        // Given a media provider with a cached avatar.
        let imageData = try makeImageData()
        mediaLoader.loadCachedMediaThumbnailForSourceWidthHeightClosure = { _, _, _ in imageData }
        let mediaProvider = await RemoteLogoutAvatarMediaProvider(remoteLogoutClientProxy: clientProxy)
        
        // When asking for some other media.
        let otherSource = try MediaSourceProxy(url: "mxc://matrix.org/other", mimeType: nil)
        
        // Then nothing is provided.
        #expect(mediaProvider.imageFromSource(otherSource, size: nil) == nil)
        await #expect(throws: MediaProviderError.self) {
            try await mediaProvider.loadImageRetryingOnReconnection(otherSource).value
        }
    }
    
    // MARK: - Helpers
    
    private func makeImageData() throws -> Data {
        try Data(contentsOf: #require(Bundle(for: UnitTestsAppCoordinator.self).url(forResource: "test_image", withExtension: "png")))
    }
    
    private func width(on screen: UserAvatarSizeOnScreen) -> UInt {
        UInt(Avatars.Size.user(on: screen).scaledSize.width)
    }
}
