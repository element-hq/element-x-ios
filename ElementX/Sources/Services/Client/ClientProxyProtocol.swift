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

import Combine
import Foundation
import MatrixRustSDK

enum ClientProxyCallback {
    case receivedSyncUpdate
    case receivedAuthError(isSoftLogout: Bool)
    case updatedRestoreToken
}

enum ClientProxyError: Error {
    case failedRetrievingAvatarURL
    case failedRetrievingDisplayName
    case failedRetrievingAccountData
    case failedSettingAccountData
    case failedRetrievingSessionVerificationController
    case failedLoadingMedia
}

@MainActor
protocol ClientProxyProtocol: MediaProxyProtocol {
    var callbacks: PassthroughSubject<ClientProxyCallback, Never> { get }
    
    var userIdentifier: String { get }

    var isSoftLogout: Bool { get }

    var deviceId: String? { get }

    var homeserver: String { get }

    var restoreToken: String? { get }
    
    var roomSummaryProvider: RoomSummaryProviderProtocol { get }
    
    func startSync()
    
    func stopSync()
    
    func roomForIdentifier(_ identifier: String) -> RoomProxyProtocol?
    
    func loadUserDisplayName() async -> Result<String, ClientProxyError>
        
    func loadUserAvatarURLString() async -> Result<String, ClientProxyError>
    
    func accountDataEvent<Content: Decodable>(type: String) async -> Result<Content?, ClientProxyError>
    
    func setAccountData<Content: Encodable>(content: Content, type: String) async -> Result<Void, ClientProxyError>
    
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError>

    func logout() async
}
