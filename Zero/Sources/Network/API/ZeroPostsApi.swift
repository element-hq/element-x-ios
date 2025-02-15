//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Alamofire
import Foundation

protocol ZeroPostsApiProtocol {
    func fetchPosts(limit: Int, skip: Int) async throws -> Result<[ZPost], Error>
    func fetchPostDetails(postId: String) async throws -> Result<ZPost, Error>
    func fetchPostReplies(postId: String, limit: Int, skip: Int) async throws -> Result<[ZPost], Error>
    func addMeowsToPst(amount: Int, postId: String) async throws -> Result<ZPost, Error>
}

class ZeroPostsApi: ZeroPostsApiProtocol {
    
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func fetchPosts(limit: Int = 10, skip: Int = 0) async throws -> Result<[ZPost], Error> {
        let parameters: [String: Any] = [
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
        case .success(let postMeow):
            return try await fetchPostDetails(postId: postId)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum FeedEndPoints {
        static let postsEndPoint = "\(ZeroContants.appServer.zeroRootUrl)api/v2/posts"
        static let postDetailsEndPoint = "\(ZeroContants.appServer.zeroRootUrl)api/v2/posts/\(FeedConstants.feed_id_path_param)"
        static let postRepliesEndPoint = "\(ZeroContants.appServer.zeroRootUrl)api/v2/posts/\(FeedConstants.feed_id_path_param)/replies"
        static let meowPostEndPoint = "\(ZeroContants.appServer.zeroRootUrl)api/v2/posts/post/\(FeedConstants.feed_id_path_param)/meow"
    }
    
    private enum FeedConstants {
        static let feed_id_path_param = "{feed_id}"
    }
}
