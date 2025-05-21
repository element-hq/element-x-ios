import Alamofire
import Foundation

protocol ZeroAuthApiProtocol {
    func login(email: String, password: String) async throws -> Result<ZMatrixSession, Error>
    
    func loginSSO(email: String, password: String) async throws -> Result<ZSSOToken, Error>
    
    func fetchSSOToken() async throws -> Result<ZSSOToken, Error>
    
    func loginWithWeb3(web3Token: String) async throws -> Result<ZSSOToken, Error>
    
    func linkMatrixUserToZero(matrixUserId: String) async throws -> Result<Void, Error>
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
    
    func loginSSO(email: String, password: String) async throws -> Result<ZSSOToken, any Error> {
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
                return .success(ssoToken)
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func fetchSSOToken() async throws -> (Result<ZSSOToken, Error>) {
        try await APIManager.shared.authorisedRequest(AuthEndPoints.ssoTokenEndPoint, method: .get, appSettings: appSettings)
    }
    
    func loginWithWeb3(web3Token: String) async throws -> Result<ZSSOToken, any Error> {
        let headers: HTTPHeaders = [
            AuthConstants.web3AuthHeaderKey : "\(AuthConstants.web3AuthTokenPrefix) \(web3Token)"
        ]
        // login user
        let authResult: Result<ZSessionDataResponse, Error> = try await APIManager.shared.request(AuthEndPoints.nonceOrAuthoriseEndpoint, method: .post, headers: headers)
        switch authResult {
        case .success(let sessionData):
            // save Access Token
            appSettings.zeroAccessToken = sessionData.accessToken
            // fetch SSO Token
            let ssoResult: Result<ZSSOToken, Error> = try await fetchSSOToken()
            switch ssoResult {
            case .success(let ssoToken):
                return .success(ssoToken)
            case .failure(let error):
                return .failure(error)
            }
            
        case .failure(let error):
            return .failure(error)
        }
    }
    
    func linkMatrixUserToZero(matrixUserId: String) async throws -> Result<Void, any Error> {
        let request = ZLinkMatrixUser(matrixUserId: matrixUserId)
        let result: Result<Void, Error> = try await APIManager.shared.authorisedRequest(AuthEndPoints.linkMatrixUserEndpoint,
                                                                                        method: .post,
                                                                                        appSettings: appSettings,
                                                                                        parameters: request.toDictionary())
        return result
    }
    
    // MARK: - Private
    
    private func fetchMatrixSession(ssoToken: String) async throws -> (Result<ZMatrixSession, Error>) {
        let homeAddress = ZeroContants.appServer.matrixHomeServerUrl
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
    
    private enum AuthEndPoints {
        private static let hostURL = ZeroContants.appServer.zeroRootUrl
        
        static let loginEndPoint = "\(hostURL)api/v2/accounts/login"
        static let ssoTokenEndPoint = "\(hostURL)accounts/ssoToken"
        static let matrixSessionEndPoint = "_matrix/client/r0/login"
        
        static let nonceOrAuthoriseEndpoint = "\(hostURL)authentication/nonceOrAuthorize"
        
        static let linkMatrixUserEndpoint = "\(hostURL)matrix/link-zero-user"
    }
    
    private enum AuthConstants {
        static let ssoTokenType = "org.matrix.login.jwt"
        static let origin = "https://zos.zero.tech"
        
        static let web3AuthHeaderKey = "Authorization"
        static let web3AuthTokenPrefix = "Web3"
    }
}
