//
// Copyright 2023 New Vector Ltd
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

import AuthenticationServices

/// Presents a web authentication session for an OIDC request.
@MainActor
class OIDCAuthenticationPresenter: NSObject {
    private let authenticationService: AuthenticationServiceProxyProtocol
    private let oidcRedirectURL: URL
    private let presentationAnchor: UIWindow
    
    init(authenticationService: AuthenticationServiceProxyProtocol, oidcRedirectURL: URL, presentationAnchor: UIWindow) {
        self.authenticationService = authenticationService
        self.oidcRedirectURL = oidcRedirectURL
        self.presentationAnchor = presentationAnchor
        super.init()
    }
    
    /// Presents a web authentication session for the supplied data.
    func authenticate(using oidcData: OIDCAuthenticationDataProxy) async -> Result<UserSessionProtocol, AuthenticationServiceError> {
        await withCheckedContinuation { continuation in
            let session = ASWebAuthenticationSession(url: oidcData.url,
                                                     callbackURLScheme: oidcRedirectURL.scheme) { [weak self] url, error in
                guard let self else { return }
                
                guard let url else {
                    if let nsError = error as? NSError,
                       nsError.domain == ASWebAuthenticationSessionErrorDomain,
                       nsError.code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(returning: .failure(AuthenticationServiceError.oidcError(.userCancellation)))
                        return
                    }
                    
                    continuation.resume(returning: .failure(AuthenticationServiceError.oidcError(.unknown)))
                    return
                }
                
                completeAuthentication(callbackURL: url, data: oidcData, continuation: continuation)
            }
            
            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = self
            session.start()
        }
    }
    
    private func completeAuthentication(callbackURL: URL,
                                        data: OIDCAuthenticationDataProxy,
                                        continuation: CheckedContinuation<Result<UserSessionProtocol, AuthenticationServiceError>, Never>) {
        Task {
            switch await authenticationService.loginWithOIDCCallback(callbackURL, data: data) {
            case .success(let userSession):
                continuation.resume(returning: .success(userSession))
            case .failure(let error):
                continuation.resume(returning: .failure(error))
            }
        }
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension OIDCAuthenticationPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { presentationAnchor }
}
