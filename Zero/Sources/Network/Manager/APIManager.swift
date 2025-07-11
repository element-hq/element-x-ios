import Alamofire
import Foundation

class APIManager {
    static let shared = APIManager()
    
    private init() { }
    
    func request<T: Decodable>(_ url: String,
                               method: HTTPMethod,
                               parameters: Parameters? = nil,
                               headers: HTTPHeaders? = nil,
                               encoding: ParameterEncoding = JSONEncoding.default) async throws -> Result<T, Error> {
        try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: .success(data))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }
        }
    }
    
    func request(_ url: String,
                 method: HTTPMethod,
                 parameters: Parameters? = nil,
                 headers: HTTPHeaders? = nil,
                 encoding: ParameterEncoding = JSONEncoding.default) async throws -> Result<Void, Error> {
        try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: method, parameters: parameters, encoding: encoding, headers: headers)
                .validate()
                .response { response in
                    switch response.result {
                    case .success:
                        continuation.resume(returning: .success(()))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }
        }
    }
    
    func authorisedRequest<T: Decodable>(_ url: String,
                                         method: HTTPMethod,
                                         appSettings: AppSettings,
                                         parameters: Parameters? = nil,
                                         headers: HTTPHeaders? = nil,
                                         encoding: ParameterEncoding = JSONEncoding.default) async throws -> Result<T, Error> {
        var authHeaders = headers
        if let accessToken = appSettings.zeroAccessToken {
            authHeaders = getAuthHeaders(headers: headers, accessToken: accessToken)
        }
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: method, parameters: parameters, encoding: encoding, headers: authHeaders)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: .success(data))
                    case .failure(let error):
                        self.checkResponseCode(error.responseCode)
                        continuation.resume(returning: .failure(error))
                    }
                }
        }
    }
    
    func authorisedRequest(_ url: String,
                           method: HTTPMethod,
                           appSettings: AppSettings,
                           parameters: Parameters? = nil,
                           headers: HTTPHeaders? = nil,
                           encoding: ParameterEncoding = JSONEncoding.default) async throws -> Result<Void, Error> {
        var authHeaders = headers
        if let accessToken = appSettings.zeroAccessToken {
            authHeaders = getAuthHeaders(headers: headers, accessToken: accessToken)
        }
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: method, parameters: parameters, encoding: encoding, headers: authHeaders)
                .validate()
                .response { response in
                    switch response.result {
                    case .success:
                        continuation.resume(returning: .success(()))
                    case .failure(let error):
                        self.checkResponseCode(error.responseCode)
                        continuation.resume(returning: .failure(error))
                    }
                }
        }
    }
    
    func debugAuthRequest(_ url: String,
                          method: HTTPMethod,
                          appSettings: AppSettings,
                          parameters: Parameters? = nil,
                          headers: HTTPHeaders? = nil,
                          encoding: ParameterEncoding = JSONEncoding.default) async throws -> Result<Void, Error> {
        var authHeaders = headers
        if let accessToken = appSettings.zeroAccessToken {
            authHeaders = getAuthHeaders(headers: headers, accessToken: accessToken)
        }
        return try await withCheckedThrowingContinuation { continuation in
            AF.request(url, method: method, parameters: parameters, encoding: encoding, headers: authHeaders)
                .validate()
                .responseString { response in
                    switch response.result {
                    case .success(let jsonString):
                        print("✅ Raw JSON String:\n\(jsonString)")
                        continuation.resume(returning: .success(()))
                    case .failure(let error):
                        print("❌ Error: \(error)")
                        continuation.resume(returning: .failure(error))
                    }
                }
        }
    }
    
    func authorisedMultipartRequest<T: Decodable>(
        _ url: String,
        mediaFile: URL?,
        appSettings: AppSettings,
        parameters: [String: String]? = nil,
        headers: HTTPHeaders? = nil
    ) async throws -> Result<T, Error> {
        var authHeaders = headers
        if let accessToken = appSettings.zeroAccessToken {
            authHeaders = getAuthHeaders(headers: headers, accessToken: accessToken)
        }
        authHeaders?.add(name: "Content-Type", value: "multipart/form-data")

        return try await withCheckedThrowingContinuation { continuation in
            AF.upload(multipartFormData: { formData in
                // Append parameters as form-data
                parameters?.forEach { key, value in
                    if let data = value.data(using: .utf8) {
                        formData.append(data, withName: key)
                    }
                }
                
                if let mediaUrl = mediaFile {
                    // Append mediaFile URL as multipart
                    formData.append(mediaUrl, withName: "file", fileName: mediaUrl.lastPathComponent, mimeType: mediaUrl.mimeType())
                }
            }, to: url, method: .post, headers: authHeaders)
            .validate()
            .responseDecodable(of: T.self) { response in
                switch response.result {
                case .success(let data):
                    continuation.resume(returning: .success(data))
                case .failure(let error):
                    self.checkResponseCode(error.responseCode)
                    continuation.resume(returning: .failure(error))
                }
            }
        }
    }
    
    private func getAuthHeaders(headers: HTTPHeaders?, accessToken: String) -> HTTPHeaders {
        var mHeaders = headers ?? HTTPHeaders()
        mHeaders.add(name: "Authorization", value: "Bearer \(accessToken)")
        return mHeaders
    }
    
    private func checkResponseCode(_ reponseCode: Int?) {
        let userAuthState = StateBus.shared.userAuthState
        if reponseCode == 401, userAuthState.isUserAuthorised() {
            StateBus.shared.onUserAuthStateChanged(.accessTokenExpired)
        }
    }
}
