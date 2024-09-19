import Foundation
import MatrixRustSDK

class ZeroMatrixUsersService {
    private let zeroUsersApi: ZeroUsersApi
    private let appSettings: AppSettings
    
    public let loggedInUserId: String
    
    private var allZeroUsers: [ZMatrixUser] = []
    
    init(zeroUsersApi: ZeroUsersApi, appSettings: AppSettings, loggedInUserId: String) {
        self.zeroUsersApi = zeroUsersApi
        self.appSettings = appSettings
        self.loggedInUserId = loggedInUserId
        
        allZeroUsers = appSettings.zeroMatrixUsers ?? []
    }
    
    func fetchZeroUser(userId: String) async throws -> ZMatrixUser? {
        if let user = getMatrixUser(userId: userId) {
            return user
        } else {
            let zeroUsersResponse = try await zeroUsersApi.fetchUsers(fromMatrixIds: [userId])
            switch zeroUsersResponse {
            case .success(let zeroUsers):
                storeUsers(zeroUsers: zeroUsers)
                return zeroUsers.first
            case .failure(let error):
                print(error)
                return nil
            }
        }
    }
    
    func fetchZeroUsers(userIds: [String]) async throws -> [ZMatrixUser] {
        let newUsersToFetch = getZeroUsersToFetch(userIds)
        if !newUsersToFetch.isEmpty {
            let zeroUsersResponse = try await zeroUsersApi.fetchUsers(fromMatrixIds: newUsersToFetch)
            switch zeroUsersResponse {
            case .success(let zeroUsers):
                storeUsers(zeroUsers: zeroUsers)
            case .failure(let error):
                print(error)
            }
        }
        return allZeroUsers
    }
    
    func getMatrixUser(userId: String) -> ZMatrixUser? {
        allZeroUsers.first(where: { $0.matrixId == userId })
    }
    
    func getMatrixUserCleaned(userId: String) -> ZMatrixUser? {
        allZeroUsers.first(where: { $0.id.rawValue == userId })
    }
    
    func getMatrixUsers(userIds: [String]) -> [ZMatrixUser] {
        userIds.compactMap { userId -> ZMatrixUser? in
            allZeroUsers.first(where: { $0.matrixId == userId })
        }
    }
    
    func getRoomMembersMapped(roomInfo: RoomInfo, lastEventSender: String?) -> [ZMatrixUser] {
        getRoomMemberIds(
            roomInfo: roomInfo,
            lastEventSender: lastEventSender
        ).compactMap { memberId -> ZMatrixUser? in
            allZeroUsers.first { $0.matrixId == memberId }
        }
    }
    
    func getRoomMemberIds(roomInfo: RoomInfo, lastEventSender: String?) -> [String] {
        var roomMemberIds: Set<String> = []
        let roomHeroIds = roomInfo.heroes.map { $0.userId }
        roomMemberIds.formUnion(roomHeroIds)
        let roomUserIdsFromPL = roomInfo.userPowerLevels.map { $0.key }
        roomMemberIds.formUnion(roomUserIdsFromPL)
        if let matrixFormattedRoomName = roomInfo.matrixFormattedRoomName(homeServerPostFix: appSettings.zeroHomeServerPostfix) {
            roomMemberIds.insert(matrixFormattedRoomName)
        }
        if let lastMessageSender = lastEventSender {
            roomMemberIds.insert(lastMessageSender)
        }
        return Array(roomMemberIds)
    }
    
    func matrixFormattedUserId(userId: String) -> String {
        userId.toMatrixUserIdFormat(appSettings.zeroHomeServerPostfix) ?? userId
    }
    
    func areUsersFetched() -> Bool { !allZeroUsers.isEmpty }
    
    func getAllRoomUsers() -> [ZMatrixUser] { allZeroUsers }
    
    private func getZeroUsersToFetch(_ userIds: [String]) -> [String] {
        let existingUserIds = allZeroUsers.map { $0.matrixId }
        return userIds.filter { !existingUserIds.contains($0) }.uniqued { $0 }
    }
    
    private func storeUsers(zeroUsers: [ZMatrixUser]) {
        var existingUsers: [ZMatrixUser] = allZeroUsers
        existingUsers.append(contentsOf: zeroUsers)
        allZeroUsers = existingUsers.uniqued(on: { $0.matrixId })
        saveZeroUsersLocally()
    }
    
    private func saveZeroUsersLocally() {
        do {
            appSettings.zeroMatrixUsers = allZeroUsers
        } catch {
            MXLog.error(error)
        }
    }
}
