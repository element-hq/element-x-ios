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
import MatrixRustSDK

/// Presents a web authentication session that will display the user's account settings page.
///
/// A web authentication session is used so that the same session used for login is available
/// meaning that the user doesn't need to sign in again. `SFSafariViewController` doesn't
/// have access to this session, and for some reason `prefersEphemeralWebBrowserSession`
/// isn't sharing the session back to Safari.
@MainActor
class OIDCAccountSettingsPresenter: NSObject {
    private let presentationAnchor: UIWindow
    private let oidcRedirectURL: URL
    private let client: ClientProxyProtocol
    private let accountAction: AccountManagementAction
    
    init(presentationAnchor: UIWindow,
         client: ClientProxyProtocol,
         accountAction: AccountManagementAction) {
        self.presentationAnchor = presentationAnchor
        self.client = client
        self.accountAction = accountAction
        oidcRedirectURL = ServiceLocator.shared.settings.oidcRedirectURL
        super.init()
    }
    
    /// Presents a web authentication session for the supplied data.
    func start() async {
        guard let url = await client.accountURL(action: accountAction) else {
            MXLog.error("Account URL is missing.")
            return
        }
        
        let session = ASWebAuthenticationSession(url: url, callbackURLScheme: oidcRedirectURL.scheme) { _, _ in }
        session.prefersEphemeralWebBrowserSession = false
        session.presentationContextProvider = self
        session.start()
    }
}

// MARK: ASWebAuthenticationPresentationContextProviding

extension OIDCAccountSettingsPresenter: ASWebAuthenticationPresentationContextProviding {
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor { presentationAnchor }
}
