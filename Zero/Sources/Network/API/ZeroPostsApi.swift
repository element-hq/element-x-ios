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
    
    // MARK: - Constants
    
    private enum FeedEndPoints {
        static let postsEndPoint = "\(ZeroContants.appServer.zeroRootUrl)api/v2/posts"
    }
}
