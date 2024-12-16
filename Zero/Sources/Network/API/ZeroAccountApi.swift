import Alamofire
import Foundation

protocol ZeroAccountApiProtocol {
    func deleteAccount() async throws -> Result<Void, Error>
}

class ZeroAccountApi: ZeroAccountApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func deleteAccount() async throws -> Result<Void, any Error> {
        let deleteAccountResult: Result<Void, Error> = try await APIManager.shared.authorisedRequest(AccountEndPoints.deleteAccountEndPoint,
                                                                                                     method: .post,
                                                                                                     appSettings: appSettings)
        switch deleteAccountResult {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum AccountEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let deleteAccountEndPoint = "\(hostURL)api/v2/accounts/delete"
    }
}
