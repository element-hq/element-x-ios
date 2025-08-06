//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine

final class FeedMediaPreFetchService {
    private let FEED_LOAD_SIZE = 30
    private let FEED_LOAD_OFFSET = 20

    private var loadedFollowingPostsCount = 0
    private var loadedAllPostsCount = 0
    private var loadedFeedRepliesCount = 0
    private var loadedUserFeedsCount = 0

    private let mediaProtocol: FeedMediaPreFetchProtocol
    private let clientProxy: ClientProxyProtocol

    private var mediaMapCache: [String: HomeScreenPostMediaInfo] = [:]

    init(mediaProtocol: FeedMediaPreFetchProtocol,
         clientProxy: ClientProxyProtocol,
         loadInitialPosts: Bool = false) {
        self.mediaProtocol = mediaProtocol
        self.clientProxy = clientProxy
        
        if loadInitialPosts {
            self.loadInitialFeeds()
        }
    }

    private func loadInitialFeeds() {
        Task.detached { [weak self] in
            guard let self else { return }
            async let following: () = self.loadHomePostsPage(following: true, currentCount: 0)
            async let all: () = self.loadHomePostsPage(following: false, currentCount: 0)
            _ = await (following, all)
        }
    }
    
    func forceRefreshHomeFeedMedia(following: Bool) {
        Task.detached { [weak self] in
            guard let self else { return }
            if following {
                loadedFollowingPostsCount = 0
                async let following: () = self.loadHomePostsPage(following: true, currentCount: 0)
                _ = await (following)
            } else {
                loadedAllPostsCount = 0
                async let all: () = self.loadHomePostsPage(following: false, currentCount: 0)
                _ = await (all)
            }
        }
    }

    func loadHomePostsPage(following: Bool, currentCount: Int) async {
        let loadedCount = following ? loadedFollowingPostsCount : loadedAllPostsCount
        if loadedCount - currentCount > FEED_LOAD_OFFSET { return }

        let result = await clientProxy.fetchZeroFeeds(channelZId: nil,
                                                      following: following,
                                                      limit: FEED_LOAD_SIZE,
                                                      skip: loadedCount)
        guard case .success(let posts) = result else {
            return
        }
        if following {
            loadedFollowingPostsCount += posts.count
        } else {
            loadedAllPostsCount += posts.count
        }

        await loadPostsMedia(posts)
    }
    
    func loadFeedRepliesPage(postId: String, currentCount: Int, isForceRefresh: Bool = false) async {
        if isForceRefresh {
            loadedFeedRepliesCount = 0
        }
        if loadedFeedRepliesCount - currentCount > FEED_LOAD_OFFSET { return }

        let result = await clientProxy.fetchFeedReplies(feedId: postId,
                                                        limit: FEED_LOAD_SIZE,
                                                        skip: loadedFeedRepliesCount)
        guard case .success(let posts) = result else {
            return
        }
        loadedFeedRepliesCount += posts.count
        await loadPostsMedia(posts)
    }
    
    func loadUserFeedsNextPage(userId: String, currentCount: Int, isForceRefresh: Bool = false) async {
        if isForceRefresh {
            loadedFeedRepliesCount = 0
        }
        if loadedUserFeedsCount - currentCount > FEED_LOAD_OFFSET { return }

        let result = await clientProxy.fetchUserFeeds(userId: userId,
                                                      limit: FEED_LOAD_SIZE,
                                                      skip: loadedUserFeedsCount)
        guard case .success(let posts) = result else {
            return
        }
        loadedUserFeedsCount += posts.count
        await loadPostsMedia(posts)
    }
    
    func reloadMedia(_ post: HomeScreenPost, onMediaReloaded: @escaping (HomeScreenPostMediaInfo) -> Void) {
        guard let mediaInfo = post.mediaInfo else { return }
        
        Task.detached {
            let file = try await self.clientProxy.loadFileFromMediaId(mediaInfo.id, key: post.id)
            if case .success(let url) = file {
                onMediaReloaded(mediaInfo.withUpdatedUrl(mediaUrl: url))
            }
        }
    }

    private func loadPostsMedia(_ posts: [ZPost]) async {
        let mediaPosts: [HomeScreenPost] = posts.compactMap { zPost in
            let post = HomeScreenPost(loggedInUserId: clientProxy.userID, post: zPost)
            return (post.mediaInfo != nil && mediaMapCache[post.id] == nil) ? post : nil
        }

        guard !mediaPosts.isEmpty else { return }

        let mediaResults = await withTaskGroup(of: (String, ZPostMedia?).self) { group in
            for post in mediaPosts {
                group.addTask {
                    let result = await withTimeout(seconds: 10) {
                        await self.clientProxy.getPostMediaInfo(mediaId: post.mediaInfo!.id)
                    }
                    if case .success(let media) = result, let remoteUrl = URL(string: media.signedUrl) {
                        let fileName = remoteUrl.sanitizedFileName(key: post.id)
                        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
                        
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            return (post.id, media.withUrl(destinationURL))
                        } else {
                            return (post.id, media)
                        }
                    } else {
                        if case .failure(let error) = result {
                            ZeroCustomEventService.shared.feedScreenEvent(parameters: [
                                "type": "Prefetch post media url",
                                "status": "Failure",
                                "postId" : post.id,
                                "postText" : post.postText ?? "",
                                "postMediaId" : post.mediaInfo?.id ?? "",
                                "error": error.localizedDescription
                            ])
                        }
                        return (post.id, nil)
                    }
                }
            }

            var output: [String: ZPostMedia] = [:]
            for await (postId, media) in group {
                if let media = media {
                    output[postId] = media
                }
            }
            return output
        }

        await updateFeedMediaStateWithResults(mediaResults)
        await loadMediaFiles(mediaResults)
    }

    private func loadMediaFiles(_ results: [String: ZPostMedia]) async {
        guard !results.isEmpty else { return }

        let finalResults = await withTaskGroup(of: (String, ZPostMedia?).self) { group in
            for (postId, media) in results {
                group.addTask {
                    guard let url = URL(string: media.signedUrl) else { return (postId, nil) }

                    do {
                        let fileResult = try await self.clientProxy.loadFileFromUrl(url, key: postId)
                        switch fileResult {
                        case .success(let localUrl):
                            return (postId, media.withUrl(localUrl))
                        case .failure(let error):
                            ZeroCustomEventService.shared.feedScreenEvent(parameters: [
                                "type": "Download post media file",
                                "status": "Failure",
                                "postId" : postId,
                                "mediaUrl": url.absoluteString,
                                "error": error.localizedDescription
                            ])
                            return (postId, nil)
                        }
                    } catch {
                        ZeroCustomEventService.shared.feedScreenEvent(parameters: [
                            "type": "Download post media file",
                            "status": "Failure",
                            "postId" : postId,
                            "mediaUrl": url.absoluteString,
                            "error": error.localizedDescription
                        ])
                        return (postId, nil)
                    }
                }
            }

            var output: [String: ZPostMedia] = [:]
            for await (postId, media) in group {
                if let media = media {
                    output[postId] = media
                }
            }
            return output
        }

        await updateFeedMediaStateWithResults(finalResults)
    }

    @MainActor
    private func updateFeedMediaStateWithResults(_ results: [String: ZPostMedia]) {
        for (postId, media) in results {
            mediaMapCache[postId] = HomeScreenPostMediaInfo(media: media)
        }
        mediaProtocol.onMediaLoaded(mediaMapCache)
    }
}
