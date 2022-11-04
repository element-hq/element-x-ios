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

import Foundation
import MatrixRustSDK

enum UserSessionStoreError: Error {
    case missingCredentials
    case failedRestoringLogin
    case failedSettingUpSession
    case failedRefreshingRestoreToken
}

protocol UserSessionStoreProtocol {
    /// Whether or not there are sessions in the store.
    var hasSessions: Bool { get }
    
    /// Returns the location to store user data for a particular username.
    var baseDirectory: URL { get }
    
    /// Restores an existing user session.
    func restoreUserSession() async -> Result<UserSession, UserSessionStoreError>
    
    /// Creates a user session for a new client from the SDK.
    func userSession(for client: Client) async -> Result<UserSession, UserSessionStoreError>

    /// Refresh the restore token of the client for a given session.
    func refreshRestorationToken(for userSession: UserSessionProtocol) -> Result<Void, UserSessionStoreError>
    
    /// Logs out of the specified session.
    func logout(userSession: UserSessionProtocol)
}
