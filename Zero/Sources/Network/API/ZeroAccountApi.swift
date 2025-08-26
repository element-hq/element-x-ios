import Alamofire
import Foundation

protocol ZeroAccountApiProtocol {
    func deleteAccount() async throws -> Result<Void, Error>
    
    func fetchWallets() async throws -> Result<[ZWallet], Error>
    
    func verifyPassword(password: String) async throws -> Result<Void, Error>
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
    
    func fetchWallets() async throws -> Result<[ZWallet], any Error> {
        let walletListResult: Result<ZWalletListResponse, Error> = try await APIManager.shared.authorisedRequest(AccountEndPoints.listWalletsEndPoint,
                                                                                                       method: .get,
                                                                                                       appSettings: appSettings)
        switch walletListResult {
        case .success(let response):
            return .success(response.wallets)
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func verifyPassword(password: String) async throws -> Result<Void, any Error> {
        let parameters: [String: Any] = ["password": password]
        let verifyPasswordResult: Result<Void, Error> = try await APIManager.shared.authorisedRequest(AccountEndPoints.verifyPasswordEndPoint,
                                                                                                      method: .post,
                                                                                                      appSettings: appSettings,
                                                                                                      parameters: parameters)
        switch verifyPasswordResult {
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
        static let listWalletsEndPoint = "\(hostURL)api/v2/accounts/wallets"
        static let verifyPasswordEndPoint = "\(hostURL)matrix/admin/reset-password"
    }
}
