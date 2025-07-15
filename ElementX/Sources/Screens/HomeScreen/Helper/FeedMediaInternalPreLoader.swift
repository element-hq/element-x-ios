//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine

final class FeedMediaInternalPreLoader {
    private let FEED_LOAD_SIZE = 30
    private let FEED_LOAD_OFFSET = 20

    private var loadedFollowingPostsCount = 0
    private var loadedAllPostsCount = 0

    private let mediaProtocol: FeedMediaInternalLoaderProtocol
    private let clientProxy: ClientProxyProtocol

    private var mediaMapCache: [String: HomeScreenPostMediaInfo] = [:]

    init(mediaProtocol: FeedMediaInternalLoaderProtocol,
         clientProxy: ClientProxyProtocol,
         appSetting: AppSettings) {
        self.mediaProtocol = mediaProtocol
        self.clientProxy = clientProxy

        if !appSetting.enableExternalMediaLoading {
            loadInitialFeeds()
        }
    }

    private func loadInitialFeeds() {
        Task.detached { [weak self] in
            guard let self else { return }
            async let following: () = self.preFetchPosts(following: true, currentCount: 0)
            async let all: () = self.preFetchPosts(following: false, currentCount: 0)
            _ = await (following, all)
        }
    }

    func preFetchFollowingPosts(currentPostsCount: Int = 0) async {
        await preFetchPosts(following: true, currentCount: currentPostsCount)
    }

    func preFetchAllPosts(currentPostsCount: Int = 0) async {
        await preFetchPosts(following: false, currentCount: currentPostsCount)
    }

    private func preFetchPosts(following: Bool, currentCount: Int) async {
        let loadedCount = following ? loadedFollowingPostsCount : loadedAllPostsCount
        if loadedCount - currentCount > FEED_LOAD_OFFSET { return }

        let result = await clientProxy.fetchZeroFeeds(channelZId: nil,
                                                      following: following,
                                                      limit: FEED_LOAD_SIZE,
                                                      skip: loadedCount)
        guard case .success(let posts) = result else { return }

        if following {
            loadedFollowingPostsCount += posts.count
        } else {
            loadedAllPostsCount += posts.count
        }

        await loadPostsMedia(posts)
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
                        let fileName = remoteUrl.lastPathComponent
                        let destinationURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(post.id)-\(fileName)")
                        MXLog.info("MEDIA_FILE: Post: \(post.id); Path: \(destinationURL.path)")
                        
                        if FileManager.default.fileExists(atPath: destinationURL.path) {
                            return (post.id, media.withUrl(destinationURL))
                        } else {
                            return (post.id, media)
                        }
                    } else {
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

                    let fileResult = try? await self.clientProxy.loadFileFromUrl(url, key: postId)
                    if case .success(let localUrl) = fileResult {
                        return (postId, media.withUrl(localUrl))
                    }
                    return (postId, nil)
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
