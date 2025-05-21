//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Alamofire
import Foundation

protocol ZeroPostsApiProtocol {
    func fetchPosts(channelZId: String?, following: Bool, limit: Int, skip: Int) async throws -> Result<[ZPost], Error>
    func fetchPostDetails(postId: String) async throws -> Result<ZPost, Error>
    func fetchPostReplies(postId: String, limit: Int, skip: Int) async throws -> Result<[ZPost], Error>
    func addMeowsToPst(amount: Int, postId: String) async throws -> Result<ZPost, Error>
    
    func createNewPost(channelZId: String, content: String, replyToPost: String?, mediaId: String?) async throws -> Result<Void, Error>
    
    func fetchUserPosts(userId: String, limit: Int, skip: Int) async throws -> Result<[ZPost], Error>
}

class ZeroPostsApi: ZeroPostsApiProtocol {
    
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func fetchPosts(channelZId: String?, following: Bool, limit: Int = 10, skip: Int = 0) async throws -> Result<[ZPost], Error> {
        var parameters: [String: Any] = [
            "limit": limit,
            "skip": skip,
            "include_replies": "true",
            "include_meows": "true"
        ]
        if channelZId == nil {
            parameters["following"] = following.description
        }
        let requestUrl = if let channel = channelZId {
            FeedEndPoints.postsEndPoint.appending("/channel/\(channel)")
        } else {
            FeedEndPoints.postsEndPoint
        }
        let result: Result<ZPosts, Error> = try await APIManager
            .shared
            .authorisedRequest(requestUrl,
                               method: .get,
                               appSettings: appSettings,
                               parameters: parameters,
                               encoding: URLEncoding.queryString)
        switch result {
        case .success(let posts):
            return .success(posts.posts)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func fetchPostDetails(postId: String) async throws -> Result<ZPost, any Error> {
        let parameters: [String: Any] = [
            "include_replies": "true",
            "include_meows": "true"
        ]
        let requestUrl = FeedEndPoints.postDetailsEndPoint
            .replacingOccurrences(of: FeedConstants.feed_id_path_param, with: postId)
        let result: Result<ZPostDetails, Error> = try await APIManager
            .shared
            .authorisedRequest(requestUrl,
                               method: .get,
                               appSettings: appSettings,
                               parameters: parameters,
                               encoding: URLEncoding.queryString)
        switch result {
        case .success(let postDetails):
            return .success(postDetails.post)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func fetchPostReplies(postId: String, limit: Int, skip: Int) async throws -> Result<[ZPost], any Error> {
        let parameters: [String: Any] = [
            "limit": limit,
            "skip": skip,
            "include_replies": "true",
            "include_meows": "true"
        ]
        let requestUrl = FeedEndPoints.postRepliesEndPoint
            .replacingOccurrences(of: FeedConstants.feed_id_path_param, with: postId)
        let result: Result<ZPostReplies, Error> = try await APIManager
            .shared
            .authorisedRequest(requestUrl,
                               method: .get,
                               appSettings: appSettings,
                               parameters: parameters,
                               encoding: URLEncoding.queryString)
        switch result {
        case .success(let postReplies):
            return .success(postReplies.replies)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func addMeowsToPst(amount: Int, postId: String) async throws -> Result<ZPost, any Error> {
        let meowAmount = ZPostMeowAmount(amount: amount)
        let requestUrl = FeedEndPoints.meowPostEndPoint
            .replacingOccurrences(of: FeedConstants.feed_id_path_param, with: postId)
        let result: Result<ZPostMeowAmountResponse, Error> = try await APIManager
            .shared
            .authorisedRequest(requestUrl,
                               method: .post,
                               appSettings: appSettings,
                               parameters: meowAmount.toDictionary())
        switch result {
        case .success(_):
            return try await fetchPostDetails(postId: postId)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func createNewPost(channelZId: String, content: String, replyToPost: String?, mediaId: String?) async throws -> Result<Void, any Error> {
        var parameters: [String: String] = ["text": content]
        if let replyToPostId = replyToPost {
            parameters["replyTo"] = replyToPostId
        }
        if let mediaId = mediaId {
            parameters["mediaId"] = mediaId
        }
        
        let requestChannelZId = channelZId.replacingOccurrences(of: ZeroContants.ZERO_CHANNEL_PREFIX, with: "")
        let requestUrl = FeedEndPoints.newPostEndPoint
            .replacingOccurrences(of: FeedConstants.channel_path_param, with: requestChannelZId)
        
        let result: Result<Void, Error> = try await APIManager.shared.authorisedRequest(requestUrl, method: .post, appSettings: appSettings, parameters: parameters)
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func fetchUserPosts(userId: String, limit: Int = 10, skip: Int = 0) async throws -> Result<[ZPost], Error> {
        var parameters: [String: Any] = [
            "user_id": userId,
            "limit": limit,
            "skip": skip,
            "include_replies": "true",
            "include_meows": "true"
        ]
        let result: Result<ZPosts, Error> = try await APIManager
            .shared
            .authorisedRequest(FeedEndPoints.postsEndPoint,
                               method: .get,
                               appSettings: appSettings,
                               parameters: parameters,
                               encoding: URLEncoding.queryString)
        switch result {
        case .success(let posts):
            return .success(posts.posts)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum FeedEndPoints {
        private static let hostUrl = ZeroContants.appServer.zeroRootUrl
        static let postsEndPoint = "\(hostUrl)api/v2/posts"
        static let postDetailsEndPoint = "\(hostUrl)api/v2/posts/\(FeedConstants.feed_id_path_param)"
        static let postRepliesEndPoint = "\(hostUrl)api/v2/posts/\(FeedConstants.feed_id_path_param)/replies"
        static let meowPostEndPoint = "\(hostUrl)api/v2/posts/post/\(FeedConstants.feed_id_path_param)/meow"
        static let newPostEndPoint = "\(hostUrl)api/v2/posts/channel/raw/\(FeedConstants.channel_path_param)"
    }
    
    private enum FeedConstants {
        static let feed_id_path_param = "{feed_id}"
        static let channel_path_param = "{channel_zid}"
    }
}
