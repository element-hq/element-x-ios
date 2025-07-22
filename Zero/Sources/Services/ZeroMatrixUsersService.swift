import Foundation
import MatrixRustSDK

class ZeroMatrixUsersService {
    private let zeroUsersApi: ZeroUserApiProtocol
    private let appSettings: AppSettings
        
    private var roomAvatarsMap: [String: String?] = [:]
    
    init(zeroUsersApi: ZeroUserApiProtocol, appSettings: AppSettings) {
        self.zeroUsersApi = zeroUsersApi
        self.appSettings = appSettings
    }
    
    func fetchZeroUser(userId: String) async throws -> ZMatrixUser? {
        let zeroUsersResponse = try await zeroUsersApi.fetchUsers(fromMatrixIds: [userId])
        switch zeroUsersResponse {
        case .success(let zeroUsers):
            startCachingFetchedUsers(zeroUsers)
            return zeroUsers.first
        case .failure(let error):
            MXLog.error(error)
            return userFromCache(userId)
        }
    }
    
    func fetchZeroUsers(userIds: [String]) async throws -> [ZMatrixUser] {
        let zeroUsersResponse = try await zeroUsersApi.fetchUsers(fromMatrixIds: userIds)
        switch zeroUsersResponse {
        case .success(let zeroUsers):
            startCachingFetchedUsers(zeroUsers)
            return zeroUsers
        case .failure(let error):
            MXLog.error(error)
            return usersFromCache(userIds)
        }
    }
    
    private func startCachingFetchedUsers(_ users: [ZMatrixUser]) {
        Task {
            cacheUsers(users)
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
    
    func updateUserInfo(displayName: String, primaryZId: String?) async throws {
        _ = try await zeroUsersApi.updateUserProfile(displayName: displayName, profileImage: nil, primaryZID: primaryZId)
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
            appSettings.zeroLoggedInUser = user
            return user
        case .failure(let failure):
            MXLog.error(failure)
            return nil
        }
    }
    
    private func cacheUsers(_ users: [ZMatrixUser]) {
        DispatchQueue.main.async {
            var cache = self.appSettings.cachedZeroUsers
            
            let newUserMap = Dictionary(uniqueKeysWithValues: users.map { ($0.matrixId, $0) })
            cache.removeAll { newUserMap.keys.contains($0.matrixId) }
            cache.append(contentsOf: newUserMap.values)
            
            self.appSettings.cachedZeroUsers = cache
        }
    }
    
    func userFromCache(_ matrixId: String) -> ZMatrixUser? {
        appSettings.cachedZeroUsers.first { $0.matrixId == matrixId }
    }
    
    func usersFromCache(_ matrixIds: [String]) -> [ZMatrixUser] {
        var users: [ZMatrixUser] = []
        let cachedUsers = appSettings.cachedZeroUsers
        for id in matrixIds {
            if let user = cachedUsers.first(where: { $0.matrixId == id }) {
                users.append(user)
            }
        }
        return users
    }
    
    func getAllCachedUsers() -> [ZMatrixUser] {
        appSettings.cachedZeroUsers
    }
}
