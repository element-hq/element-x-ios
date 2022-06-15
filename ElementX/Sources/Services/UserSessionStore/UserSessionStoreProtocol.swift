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
}

@MainActor
protocol UserSessionStoreProtocol {
    /// Whether or not there are sessions in the store.
    var hasSessions: Bool { get }
    
    /// Restores an existing user session.
    func restoreUserSession() async -> Result<UserSession, UserSessionStoreError>
    
    /// Creates a user session for a new client from the SDK.
    func userSession(for client: Client) async -> Result<UserSession, UserSessionStoreError>
    
    /// Logs out of the specified session.
    func logout(userSession: UserSessionProtocol)
    
    /// Returns the location to store user data for a particular username.
    func baseDirectoryPath(for username: String) -> String
}
