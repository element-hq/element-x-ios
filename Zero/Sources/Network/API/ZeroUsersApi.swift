import Alamofire
import Foundation

protocol ZeroUsersApiProtocol {
    func fetchUsers(fromMatrixIds ids: [String]) async throws -> Result<[ZMatrixUser], any Error>
    
    func updateUserProfile(displayName: String?, profileImage: String?, primaryZID: String?) async throws -> Result<Void, Error>
}

class ZeroUsersApi: ZeroUsersApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func fetchUsers(fromMatrixIds ids: [String]) async throws -> Result<[ZMatrixUser], any Error> {
        let parameters: Parameters = [
            "matrixIds": ids
        ]
        
        let result: Result<[ZMatrixUser], Error> = try await APIManager
            .shared
            .authorisedRequest(UserEndPoints.matrixUsersEndPoint,
                               method: .post,
                               appSettings: appSettings,
                               parameters: parameters)
        
        switch result {
        case .success(let matrixUsers):
            return .success(matrixUsers)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func searchUsers(_ query: String, offset: Int = 0, limit: Int = 25) async throws -> Result<[ZMatrixSearchedUser], any Error> {
        let items: [String: Any] = [
            "filter": query,
            "isMatrixEnabled": true,
            "limit": limit,
            "offset": offset
        ]
        let jsonData = try! JSONSerialization.data(withJSONObject: items)
        let json = String(data: jsonData, encoding: .utf8)!
        
        let parameters: Parameters = [
            "filter": json
        ]
        let result: Result<[ZMatrixSearchedUser], Error> = try await APIManager
            .shared
            .authorisedRequest(UserEndPoints.matrixSearchUsersEndPoint,
                               method: .get,
                               appSettings: appSettings,
                               parameters: parameters,
                               encoding: URLEncoding.queryString)
        switch result {
        case .success(let users):
            return .success(users)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func updateUserProfile(displayName: String?, profileImage: String?, primaryZID: String?) async throws -> Result<Void, any Error> {
        var profileParams: [String: String] = [:]
        if let displayName { profileParams["firstName"] = displayName }
        if let profileImage { profileParams["profileImage"] = profileImage }
        if let primaryZID { profileParams["primaryZID"] = primaryZID }
        
        let parameters: Parameters = [
            "profileData": profileParams
        ]
        
        let result: Result<Void, Error> = try await APIManager
            .shared
            .authorisedRequest(UserEndPoints.matrixUpdateUserProfileEndPoint,
                               method: .put,
                               appSettings: appSettings,
                               parameters: parameters)
        
        switch result {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum UserEndPoints {
        static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let matrixUsersEndPoint = "\(hostURL)matrix/users/zero"
        static let matrixSearchUsersEndPoint = "\(hostURL)api/v2/users/searchInNetworksByName"
        static let matrixUpdateUserProfileEndPoint = "\(hostURL)api/v2/users/profile"
    }
}
