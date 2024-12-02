import Alamofire
import Foundation

protocol ZeroCreateAccountApiProtocol {
    func validateInviteCode(inviteCode: String) async throws -> Result<Void, Error>
    
    func createAccountWithEmail(email: String, password: String, invite: String) async throws -> Result<ZSessionDataResponse, Error>
    
    func finaliseCreateAccount(request: ZFinaliseCreateAccount) async throws -> Result<ZMatrixUser, Error>
}

class ZeroCreateAccountApi: ZeroCreateAccountApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func validateInviteCode(inviteCode: String) async throws -> Result<Void, any Error> {
        let url = CreateAccountEndPoints.validateInviteCodeEndPoint
            .replacingOccurrences(of: CreateAccountConstants.invite_code_path_param, with: inviteCode)
        let validateCodeResult: Result<Void, Error> = try await APIManager.shared.request(url, method: .post)
        switch validateCodeResult {
        case .success:
            return .success(())
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func createAccountWithEmail(email: String, password: String, invite: String) async throws -> Result<ZSessionDataResponse, any Error> {
        let nonceResult: Result<ZNonceResponse, Error> = try await APIManager.shared.request(CreateAccountEndPoints.authenticateNonceEndPoint, method: .post)
        switch nonceResult {
        case .success(let nonceResponse):
            /// Call create account api
            let headers: HTTPHeaders = [
                "Authorization": nonceResponse.nonceHeaderToken
            ]
            let request = ZCreateAccount.newRequest(email: email, password: password, invite: invite)
            let createAccountResult: Result<ZSessionDataResponse, Error> = try await APIManager.shared.request(CreateAccountEndPoints.createAccountEndPoint, method: .post, parameters: request.toDictionary(), headers: headers)
            switch createAccountResult {
            case .success(let sessionData):
                // save Access Token
                appSettings.zeroAccessToken = sessionData.accessToken
                return .success(sessionData)
            case .failure(let error):
                return .failure(error)
            }
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func finaliseCreateAccount(request: ZFinaliseCreateAccount) async throws -> Result<ZMatrixUser, Error> {
        let finaliseResult: Result<ZMatrixUser, Error> = try await APIManager.shared.authorisedRequest(CreateAccountEndPoints.finaliseSignupEndPoint, method: .post, appSettings: appSettings, parameters: request.toDictionary())
        switch finaliseResult {
        case .success(let inviter):
            return .success(inviter)
        case.failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Constants
    
    private enum CreateAccountEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let validateInviteCodeEndPoint = "\(hostURL)invite/\(CreateAccountConstants.invite_code_path_param)/validate"
        static let authenticateNonceEndPoint = "\(hostURL)authentication/nonce"
        
        static let createAccountEndPoint = "\(hostURL)api/v2/accounts/createAndAuthorize"
        static let finaliseSignupEndPoint = "\(hostURL)api/v2/accounts/finalize"
    }
    
    private enum CreateAccountConstants {
        static let invite_code_path_param = "{invite_code}"
    }
}
