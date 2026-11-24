//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UIKit

/// Provides the avatar of an account that the server logged out, loaded from its client's cache before the account's data is deleted.
nonisolated struct RemoteLogoutAvatarMediaProvider: MediaProviderProtocol {
    private let avatarURL: URL?
    private let avatar: UIImage?
    
    @MainActor
    init(remoteLogoutClientProxy clientProxy: ClientProxyProtocol) async {
        let avatarURL = clientProxy.userProfilePublisher.value.avatarURL
        self.avatarURL = avatarURL
        avatar = await clientProxy.mediaLoader.loadCachedAvatar(avatarURL: avatarURL)
    }
    
    // MARK: Images
    
    func imageFromSource(_ source: MediaSourceProxy?, size: CGSize?) -> UIImage? {
        guard let avatarURL, source?.url == avatarURL else { return nil }
        return avatar
    }
    
    func loadImageRetryingOnReconnection(_ source: MediaSourceProxy, size: CGSize?) -> Task<UIImage, Error> {
        let image = imageFromSource(source, size: size)
        return Task {
            guard let image else { throw MediaProviderError.failedRetrievingImage }
            return image
        }
    }
    
    func loadImageDataFromSource(_ source: MediaSourceProxy) async -> Result<Data, MediaProviderError> {
        .failure(.failedRetrievingImage)
    }
    
    // MARK: Files
    
    func loadFileFromSource(_ source: MediaSourceProxy, filename: String?) async -> Result<MediaFileHandleProxy, MediaProviderError> {
        .failure(.failedRetrievingFile)
    }
    
    // MARK: Thumbnail
    
    func loadThumbnailForSource(source: MediaSourceProxy, size: CGSize) async -> Result<Data, MediaProviderError> {
        .failure(.failedRetrievingThumbnail)
    }
}

// MARK: - Private

private extension MediaLoaderProtocol {
    /// Loads the given URL from the store, trying the ideal size and then a fallback size that is likely cached::
    /// - the account info card's (also used for the compact chats screen, fetched on iPad app launch)
    /// - the chats screen's (fetched on iPhone app launch)
    func loadCachedAvatar(avatarURL: URL?) async -> UIImage? {
        guard let avatarURL, let source = try? MediaSourceProxy(url: avatarURL, mimeType: nil) else { return nil }
        
        let sizes: [UserAvatarSizeOnScreen] = [.accountInfoCard, .chats]
        for size in sizes {
            let scaledSize = Avatars.Size.user(on: size).scaledSize
            if let data = try? await loadCachedMediaThumbnailForSource(source, width: UInt(scaledSize.width), height: UInt(scaledSize.height)),
               let image = UIImage(data: data) {
                return image
            }
        }
        
        return nil
    }
}
