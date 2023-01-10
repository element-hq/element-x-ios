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

class MockClientProxy: ClientProxyProtocol {
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    let userIdentifier: String
    let isSoftLogout = false
    let deviceId: String? = nil
    let homeserver = ""
    let restorationToken: RestorationToken? = nil
    
    var visibleRoomsSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()
    
    var allRoomsSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()
    
    internal init(userIdentifier: String, roomSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()) {
        self.userIdentifier = userIdentifier
        visibleRoomsSummaryProvider = roomSummaryProvider
    }
    
    func startSync() { }
    
    func stopSync() { }
    
    func restartSync() { }
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol? {
        guard let room = visibleRoomsSummaryProvider?.roomListPublisher.value.first(where: { $0.id == identifier }) else {
            return nil
        }
    
        switch room {
        case .empty:
            return MockRoomProxy(displayName: "Empty room")
        case .filled(let details), .invalidated(let details):
            return MockRoomProxy(displayName: details.name)
        }
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
    
    var sessionVerificationControllerProxyResult: Result<SessionVerificationControllerProxyProtocol, ClientProxyError>?
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        if let sessionVerificationControllerProxyResult {
            return sessionVerificationControllerProxyResult
        } else {
            return .failure(.failedRetrievingSessionVerificationController)
        }
    }
    
    func logout() async {
        // no-op
    }
    
    var setPusherCalled = false
    var setPusherErrorToThrow: Error?
    var setPusherPushkey: String?
    var setPusherKind: PusherKind?
    var setPusherAppId: String?
    var setPusherAppDisplayName: String?
    var setPusherDeviceDisplayName: String?
    var setPusherProfileTag: String?
    var setPusherLang: String?
    var setPusherUrl: String?
    var setPusherFormat: PushFormat?
    var setPusherDefaultPayload: [AnyHashable: Any]?
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
        if let setPusherErrorToThrow { throw setPusherErrorToThrow }
        setPusherCalled = true
        setPusherPushkey = pushkey
        setPusherKind = kind
        setPusherAppId = appId
        setPusherAppDisplayName = appDisplayName
        setPusherDeviceDisplayName = deviceDisplayName
        setPusherProfileTag = profileTag
        setPusherLang = lang
        setPusherUrl = url
        setPusherFormat = format
        setPusherDefaultPayload = defaultPayload
    }
}
