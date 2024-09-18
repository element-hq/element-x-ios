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
        
        return try await withCheckedThrowingContinuation({ continuation in
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
        })
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
        return try await withCheckedThrowingContinuation({ continuation in
            AF.request(url, method: method, parameters: parameters, encoding: encoding, headers: authHeaders)
                .validate()
                .responseDecodable(of: T.self) { response in
                    switch response.result {
                    case .success(let data):
                        continuation.resume(returning: .success(data))
                    case .failure(let error):
                        continuation.resume(returning: .failure(error))
                    }
                }
        })
    }
    
    private func getAuthHeaders(headers: HTTPHeaders?, accessToken: String) -> HTTPHeaders {
        var mHeaders = headers ?? HTTPHeaders()
        mHeaders.add(name: "Authorization", value: "Bearer \(accessToken)")
        return mHeaders
    }
}
