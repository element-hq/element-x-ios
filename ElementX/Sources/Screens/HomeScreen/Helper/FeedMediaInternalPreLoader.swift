//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import Combine

final class FeedMediaInternalPreLoader {
    private let FEED_LOAD_SIZE = 40
    private let FEED_LOAD_OFFSET = 20
    
    private var loadedFollowingPostsCount: Int = 0
    private var loadedAllPostsCount: Int = 0
    
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
        Task.detached {
            async let followingPosts: () = self.preFetchFollowingPosts()
            async let allPosts: () = self.preFetchAllPosts()
            _ = await (followingPosts, allPosts)
        }
    }
    
    func preFetchFollowingPosts(currentPostsCount: Int = 0) async {
        let diff = loadedAllPostsCount - currentPostsCount
        if diff < FEED_LOAD_OFFSET {
            let result = await clientProxy.fetchZeroFeeds(channelZId: nil, following: true, limit: FEED_LOAD_SIZE, skip: loadedFollowingPostsCount)
            if case .success(let posts) = result {
                loadedFollowingPostsCount += posts.count
                loadPostsMedia(post: posts)
            }
        }
    }
    
    func preFetchAllPosts(currentPostsCount: Int = 0) async {
        let diff = loadedAllPostsCount - currentPostsCount
        if diff < FEED_LOAD_OFFSET {
            let result = await clientProxy.fetchZeroFeeds(channelZId: nil, following: false, limit: FEED_LOAD_SIZE, skip: loadedAllPostsCount)
            if case .success(let posts) = result {
                loadedAllPostsCount += posts.count
                loadPostsMedia(post: posts)
            }
        }
    }
    
    private func loadPostsMedia(post: [ZPost]) {
        Task.detached {
            let mediaPosts = post.compactMap { zPost in
                zPost.mediaId != nil ? HomeScreenPost(loggedInUserId: self.clientProxy.userID, post: zPost) : nil
            }
            await withTaskGroup(of: (HomeScreenPost, ZPostMedia?).self) { group in
                for post in mediaPosts {
                    
                    guard !Task.isCancelled else { continue }
                    
                    group.addTask {
                        guard let mediaId = post.mediaInfo?.id else { return (post, nil) }
                        let result = await withTimeout(seconds: 10, operation: {
                            await self.clientProxy.getPostMediaInfo(mediaId: mediaId)
                        })
                        
                        guard !Task.isCancelled else { return (post, nil) }
                        
                        if case .success(let media) = result {
                            return (post, media)
                        }
                        return (post, nil)
                    }
                }
                
                var results: [String: ZPostMedia] = [:]
                for await (post, media) in group {
                    if let media = media {
                        results[post.id] = media
                    }
                }
                // Initially remote media urls will be set in case downloading takes time
                await self.updateFeedMediaStateWithResults(results)
                
                // Start downloading the images locally
                self.loadMediaFiles(results)
            }
        }
    }
    
    private func loadMediaFiles(_ results: [String: ZPostMedia]) {
        Task.detached {
            await withTaskGroup(of: (String, ZPostMedia?).self) { group in
                for (postId, media) in results {
                    
                    guard !Task.isCancelled else { continue }
                    
                    group.addTask {
                        guard let url = URL(string: media.signedUrl) else { return (postId, nil) }
                        
                        do {
                            let fileResult = try await self.clientProxy.loadFileFromUrl(url)
                            MXLog.info("FEED_DOWNLOAD_FILE_URL:  \(url.absoluteString)")
                            
                            guard !Task.isCancelled else { return (postId, nil) }
                            
                            if case .success(let localUrl) = fileResult {
                                return (postId, media.withUrl(localUrl))
                            }
                            return (postId, nil)
                        } catch {
                            return (postId, nil)
                        }
                    }
                }
                
                var results: [String: ZPostMedia] = [:]
                for await (postId, media) in group {
                    if let media = media {
                        results[postId] = media
                    }
                }
                // send local media urls now
                await self.updateFeedMediaStateWithResults(results)
            }
        }
    }
    
    @MainActor
    private func updateFeedMediaStateWithResults(_ results: [String: ZPostMedia]) {
        for (postId, media) in results {
            self.mediaMapCache[postId] = HomeScreenPostMediaInfo(media: media)
        }
        mediaProtocol.onMediaLoaded(mediaMapCache)
    }
}
