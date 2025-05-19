//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Alamofire
import Foundation

protocol ZeroPostUserApiProtocol {
    func fetchUserProfile(userZId: String) async throws -> Result<ZPostUserProfile, any Error>
    
    func fetchUserFollowingStatus(userId: String) async throws -> Result<ZPostUserFollowingStatus, any Error>
    
    func followPostUser(userId: String) async throws -> Result<ZPostUserFollowResponse, any Error>
    
    func unFollowPostUser(userId: String) async throws -> Result<Void, any Error>
}

class ZeroPostUserApi : ZeroPostUserApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func fetchUserProfile(userZId: String) async throws -> Result<ZPostUserProfile, any Error> {
        let url = PostUserEndPoints.userProfileEndPoint
            .replacingOccurrences(of: PostUserConstants.user_zid_path_param, with: userZId)
        let result: Result<ZPostUserProfile, Error> = try await APIManager
            .shared
            .authorisedRequest(url,
                               method: .get,
                               appSettings: appSettings)
        
        switch result {
        case .success(let profile):
            return .success(profile)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func fetchUserFollowingStatus(userId: String) async throws -> Result<ZPostUserFollowingStatus, any Error> {
        let url = PostUserEndPoints.userFollowsEndPoint
            .replacingOccurrences(of: PostUserConstants.user_id_path_param, with: userId)
            .appending(PostUserConstants.user_follows_status_url_path)
        let result: Result<ZPostUserFollowingStatus, Error> = try await APIManager
            .shared
            .authorisedRequest(url,
                               method: .get,
                               appSettings: appSettings)
        
        switch result {
        case .success(let status):
            return .success(status)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func followPostUser(userId: String) async throws -> Result<ZPostUserFollowResponse, any Error> {
        let url = PostUserEndPoints.userFollowsEndPoint
            .replacingOccurrences(of: PostUserConstants.user_id_path_param, with: userId)
        let result: Result<ZPostUserFollowResponse, Error> = try await APIManager
            .shared
            .authorisedRequest(url,
                               method: .post,
                               appSettings: appSettings)
        
        switch result {
        case .success(let follow):
            return .success(follow)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func unFollowPostUser(userId: String) async throws -> Result<Void, any Error> {
        let url = PostUserEndPoints.userFollowsEndPoint
            .replacingOccurrences(of: PostUserConstants.user_id_path_param, with: userId)
        let result: Result<Void, Error> = try await APIManager
            .shared
            .authorisedRequest(url,
                               method: .delete,
                               appSettings: appSettings)
        
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum PostUserEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let userProfileEndPoint = "\(hostURL)api/v2/users/profile/zid/\(PostUserConstants.user_zid_path_param)"
        static let userFollowsEndPoint = "\(hostURL)api/v2/user-follows/\(PostUserConstants.user_id_path_param)"
    }
    
    private enum PostUserConstants {
        static let user_zid_path_param = "{user_zid}"
        static let user_id_path_param = "{user_id}"
        
        static let user_follows_status_url_path = "/status"
    }
}
