//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import AppAuth

/// Errors thrown by the OIDC service.
enum OIDCError: Error {
    case notSupported
    case metadataMissingRegistrationEndpoint
    case userCancellation
    case missingTokenExchangeRequest
    case unknown
}

/// A proof of concept implementation of a service that assists with authentication via OIDC.
/// It will be replaced by an implementation in the Rust SDK tracked in the following issue:
/// https://github.com/matrix-org/matrix-rust-sdk/issues/859
class OIDCService {
    private let issuerURL: URL
    private var authState: OIDAuthState
    
    private var metadata: OIDServiceConfiguration?
    /// Redirect URI for the request. Must match the `client_uri` in reverse DNS format.
    private var redirectURI: URL {
        guard let url = URL(string: "io.element:/callback") else {
            fatalError("The redirect URI should never fail parsing")
        }
        
        return url
    }
    
    /// Maintains a strong ref to the authorization session that's in progress.
    private var session: OIDExternalUserAgentSession?
    
    init(issuerURL: URL) {
        self.issuerURL = issuerURL
        authState = OIDAuthState(authorizationResponse: nil, tokenResponse: nil, registrationResponse: nil)
    }
    
    /// Get OpenID Connect endpoints and ensure that dynamic client registration is configured.
    func metadata() async throws -> OIDServiceConfiguration {
        let metadata = try await OIDAuthorizationService.discoverConfiguration(forIssuer: issuerURL)
        
        guard metadata.registrationEndpoint != nil else {
            throw OIDCError.metadataMissingRegistrationEndpoint
        }
        
        return metadata
    }
    
    /// Perform dynamic client registration and then store the response
    func registerClient(metadata: OIDServiceConfiguration) async throws -> OIDRegistrationResponse {
        let extraParams = [
            "client_name": "ElementX iOS",
            "client_uri": "https://element.io",
            "tos_uri": "https://element.io/user-terms-of-service",
            "policy_uri": "https://element.io/privacy"
        ]
        
        let nonTemplatizedRequest = OIDRegistrationRequest(
            configuration: metadata,
            redirectURIs: [redirectURI],
            responseTypes: nil,
            grantTypes: [OIDGrantTypeAuthorizationCode, OIDGrantTypeRefreshToken],
            subjectType: nil,
            tokenEndpointAuthMethod: "none",
            additionalParameters: extraParams
        )
        
        let registrationResponse = try await OIDAuthorizationService.perform(nonTemplatizedRequest)
        
        MXLog.info("Registration data retrieved successfully")
        MXLog.debug("Created dynamic client: ID: \(registrationResponse.clientID)")
        
        // This is a PoC, a complete implementation would persist the client ID and secret for reuse.
        
        return registrationResponse
    }
    
    /// Trigger a redirect with standard parameters.
    /// `acr_values` can be sent as an extra parameter, to control authentication methods.
    func presentWebAuthentication(metadata: OIDServiceConfiguration,
                                  clientID: String,
                                  scope: String,
                                  userAgent: OIDExternalUserAgent) async throws -> OIDAuthorizationResponse {
        let scopesArray = scope.components(separatedBy: " ")
        let request = OIDAuthorizationRequest(configuration: metadata,
                                              clientId: clientID,
                                              clientSecret: nil,
                                              scopes: scopesArray,
                                              redirectURL: redirectURI,
                                              responseType: OIDResponseTypeCode,
                                              additionalParameters: nil)
        let result: OIDAuthorizationResponse = try await withCheckedThrowingContinuation { continuation in
            self.session = OIDAuthorizationService.present(request, externalUserAgent: userAgent) { response, error in
                guard let response = response else {
                    if let error = error {
                        MXLog.info("User cancelled the ASWebAuthenticationSession window")
                        continuation.resume(with: .failure(self.isUserCancellationError(error) ? OIDCError.userCancellation : error))
                    } else {
                        continuation.resume(with: .failure(OIDCError.unknown))
                    }
                    return
                }
                
                MXLog.info("Authorization response received successfully")
                continuation.resume(with: .success(response))
            }
        }
        return result
    }
    
    /// Handle the authorization response, including the user closing the Chrome Custom Tab
    func redeemCodeForTokens(authResponse: OIDAuthorizationResponse) async throws -> OIDTokenResponse {
        guard let request = authResponse.tokenExchangeRequest() else { throw OIDCError.missingTokenExchangeRequest }
        return try await OIDAuthorizationService.perform(request, originalAuthorizationResponse: authResponse)
    }
    
    /// We can check for specific error codes to handle the user cancelling the ASWebAuthenticationSession window.
    private func isUserCancellationError(_ error: Error) -> Bool {
        let error = error as NSError
        return error.domain == OIDGeneralErrorDomain && error.code == OIDErrorCode.userCanceledAuthorizationFlow.rawValue
    }
}

extension OIDAuthorizationService {
    /// An async version of `perform(_:originalAuthorizationResponse:callback:)`.
    class func perform(_ request: OIDTokenRequest,
                       originalAuthorizationResponse authorizationResponse: OIDAuthorizationResponse?) async throws -> OIDTokenResponse {
        try await withCheckedThrowingContinuation { continuation in
            perform(request, originalAuthorizationResponse: authorizationResponse) { response, error in
                guard let response = response else {
                    continuation.resume(with: .failure(error ?? OIDCError.unknown))
                    return
                }
                continuation.resume(with: .success(response))
            }
        }
    }
}
