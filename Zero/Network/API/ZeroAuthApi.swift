import Alamofire
import Foundation

protocol ZeroAuthApiProtocol {
    func login(email: String, password: String) async throws -> Result<ZMatrixSession, Error>
}

class ZeroAuthApi: ZeroAuthApiProtocol {
    private let appSettings: AppSettings
    
    init(appSettings: AppSettings) {
        self.appSettings = appSettings
    }
    
    // MARK: - Public
    
    func login(email: String, password: String) async throws -> Result<ZMatrixSession, any Error> {
        let parameters: Parameters = [
            "email": email,
            "password": password
        ]
        // login user
        let authResult: Result<ZSessionDataResponse, Error> = try await APIManager.shared.request(AuthEndPoints.loginEndPoint, method: .post, parameters: parameters)
        switch authResult {
        case .success(let sessionData):
            // save Access Token
            appSettings.zeroAccessToken = sessionData.accessToken
            // fetch SSO Token
            let ssoResult: Result<ZSSOToken, Error> = try await fetchSSOToken()
            switch ssoResult {
            case .success(let ssoToken):
                // fetch matrix session
                let sessionResult: Result<ZMatrixSession, Error> = try await fetchMatrixSession(ssoToken: ssoToken.token)
                switch sessionResult {
                case .success(let matrixSession):
                    return .success(matrixSession)
                case .failure(let error):
                    return .failure(error)
                }
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    // MARK: - Private
    
    private func fetchSSOToken() async throws -> (Result<ZSSOToken, Error>) {
        return try await APIManager.shared.authorisedRequest(AuthEndPoints.ssoTokenEndPoint, method: .get, appSettings: self.appSettings)
    }
    
    private func fetchMatrixSession(ssoToken: String) async throws -> (Result<ZMatrixSession, Error>) {
        let homeAddress = appSettings.defaultHomeserverAddress
        let url = "\(homeAddress)/\(AuthEndPoints.matrixSessionEndPoint)"
        var host = ""
        if let range = homeAddress.range(of: "https://") {
            host = String(homeAddress[range.upperBound...])
        } else {
            host = homeAddress
        }
        let parameters: Parameters = [
            "token": ssoToken,
            "type": AuthConstants.ssoTokenType
        ]
        let headers: HTTPHeaders = [
            "Host": host,
            "Origin": AuthConstants.origin
        ]
        return try await APIManager.shared.request(url, method: .post, parameters: parameters, headers: headers)
    }
    
    // MARK: - Constants
    
    private struct AuthEndPoints {
        static let hostURL = APIConfigs.zeroURLRoot
        
        static let loginEndPoint = "\(hostURL)api/v2/accounts/login"
        static let ssoTokenEndPoint = "\(hostURL)accounts/ssoToken"
        static let matrixSessionEndPoint = "_matrix/client/r0/login"
    }
    
    private struct AuthConstants {
        static let ssoTokenType = "org.matrix.login.jwt"
        static let origin = "https://zos.zero.tech"
    }
}
