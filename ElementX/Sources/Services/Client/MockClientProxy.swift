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

struct MockClientProxy: ClientProxyProtocol {
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    let userIdentifier: String
    let isSoftLogout = false
    let deviceId: String? = nil
    let homeserver = ""
    let restorationToken: RestorationToken? = nil
    
    var roomSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()
    
    func startSync() { }
    
    func stopSync() { }
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol? {
        nil
    }
    
    func loadUserDisplayName() async -> Result<String, ClientProxyError> {
        .success("User display name")
    }
    
    func loadUserAvatarURLString() async -> Result<String, ClientProxyError> {
        .failure(.failedRetrievingAvatarURL)
    }
    
    func accountDataEvent<Content>(type: String) async -> Result<Content?, ClientProxyError> where Content: Decodable {
        .failure(.failedRetrievingAccountData)
    }
    
    func setAccountData<Content>(content: Content, type: String) async -> Result<Void, ClientProxyError> where Content: Encodable {
        .failure(.failedSettingAccountData)
    }
    
    func mediaSourceForURLString(_ urlString: String) -> MediaSourceProxy {
        .init(urlString: urlString)
    }
    
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        throw ClientProxyError.failedLoadingMedia
    }
    
    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        throw ClientProxyError.failedLoadingMedia
    }
    
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        .failure(.failedRetrievingSessionVerificationController)
    }

    func logout() async {
        // no-op
    }

    // swiftlint:disable:next function_parameter_count
    func setPusher(pushkey: String,
                   kind: PusherKind?,
                   appId: String,
                   appDisplayName: String,
                   deviceDisplayName: String,
                   profileTag: String?,
                   lang: String,
                   url: String?,
                   format: PushFormat?,
                   defaultPayload: [AnyHashable: Any]?) async throws {
        // no-op
    }
}
