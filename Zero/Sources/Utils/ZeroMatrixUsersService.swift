import Foundation
import MatrixRustSDK

class ZeroMatrixUsersService {
    private let zeroUsersApi: ZeroUsersApiProtocol
    private let appSettings: AppSettings
    private let client: ClientProtocol
        
    private var allUserProfiles: Set<UserProfile> = []
    private var roomAvatarsMap: [String: String?] = [:]
    
    var loggedInUserId: String {
        (try? client.userId()) ?? ""
    }
    
    init(zeroUsersApi: ZeroUsersApiProtocol, appSettings: AppSettings, client: ClientProtocol) {
        self.zeroUsersApi = zeroUsersApi
        self.appSettings = appSettings
        self.client = client
    }
    
    func fetchZeroUser(userId: String) async throws -> ZMatrixUser? {
        let zeroUsersResponse = try await zeroUsersApi.fetchUsers(fromMatrixIds: [userId])
        switch zeroUsersResponse {
        case .success(let zeroUsers):
            return zeroUsers.first
        case .failure(let error):
            MXLog.error(error)
            return nil
        }
    }
    
    func fetchZeroUsers(userIds: [String]) async throws -> [ZMatrixUser] {
        let zeroUsersResponse = try await zeroUsersApi.fetchUsers(fromMatrixIds: userIds)
        switch zeroUsersResponse {
        case .success(let zeroUsers):
            return zeroUsers
        case .failure(let error):
            MXLog.error(error)
            return []
        }
    }
    
    func searchZeroUsers(query: String) async throws -> [ZMatrixSearchedUser] {
        let response = try await zeroUsersApi.searchUsers(query, offset: 0, limit: 25)
        switch response {
        case .success(let zeroUsers):
            return zeroUsers
        case .failure(let error):
            MXLog.error(error)
            return []
        }
    }
    
    func updateUserAvatar(avatarUrl: String) async throws {
        _ = try await zeroUsersApi.updateUserProfile(displayName: nil, profileImage: avatarUrl, primaryZID: nil)
    }
    
    func updateUserName(displayName: String) async throws {
        _ = try await zeroUsersApi.updateUserProfile(displayName: displayName, profileImage: nil, primaryZID: nil)
    }
    
    func getMatrixUserProfile(userId: String) async throws -> UserProfile {
        if let cachedUser = allUserProfiles.first(where: { $0.userId == userId }) {
            return cachedUser
        } else {
            let remoteUser = try await client.getProfile(userId: userId)
            DispatchQueue.main.async {
                self.allUserProfiles.insert(remoteUser)
            }
            return remoteUser
        }
    }
    
    func setRoomAvatarInCache(roomId: String, avatarUrl: String?) {
        DispatchQueue.main.async {
            self.roomAvatarsMap[roomId] = avatarUrl
        }
    }
    
    func getRoomAvatarFromCache(roomId: String) -> String? {
        roomAvatarsMap[roomId] ?? nil
    }
    
    func fetchCurrentUser() async throws -> ZCurrentUser? {
        let result = try await zeroUsersApi.fetchCurrentUser()
        switch result {
        case .success(let user):
            return user
        case .failure(let failure):
            MXLog.error(failure)
            return nil
        }
    }
}
