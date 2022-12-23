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
@testable import ElementX
import Foundation

class ClientProxyMock: ClientProxyProtocol {
    var sessionVerificationControllerProxyResult: Result<ElementX.SessionVerificationControllerProxyProtocol, ClientProxyError>?
    
    var visibleRoomsSummaryProvider: ElementX.RoomSummaryProviderProtocol?
    
    var allRoomsSummaryProvider: ElementX.RoomSummaryProviderProtocol?
    
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    var userIdentifier = ""
    
    var isSoftLogout = false
    
    var deviceId: String? = ""
    
    var homeserver = ""
    
    var restorationToken: ElementX.RestorationToken?
    
    var roomSummaryProvider: ElementX.RoomSummaryProviderProtocol?
    
    internal init() { }
    
    func startSync() { }
    
    func stopSync() { }
    
    func restartSync() { }
    
    func roomForIdentifier(_ identifier: String) async -> ElementX.RoomProxyProtocol? {
        nil
    }
    
    func loadUserDisplayName() async -> Result<String, ElementX.ClientProxyError> {
        .failure(.failedLoadingMedia)
    }
    
    func loadUserAvatarURLString() async -> Result<String, ElementX.ClientProxyError> {
        .failure(.failedLoadingMedia)
    }
    
    func accountDataEvent<Content>(type: String) async -> Result<Content?, ClientProxyError> where Content: Decodable {
        .failure(.failedLoadingMedia)
    }
    
    func setAccountData<Content>(content: Content, type: String) async -> Result<Void, ClientProxyError> where Content: Encodable {
        .failure(.failedLoadingMedia)
    }

    func sessionVerificationControllerProxy() async -> Result<ElementX.SessionVerificationControllerProxyProtocol, ClientProxyError> {
        if let sessionVerificationControllerProxyResult {
            return sessionVerificationControllerProxyResult
        } else {
            return .failure(.failedLoadingMedia)
        }
    }
    
    func logout() async { }
    
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
    func setPusher(pushkey: String, kind: PusherKind?, appId: String, appDisplayName: String, deviceDisplayName: String, profileTag: String?, lang: String, url: String?, format: PushFormat?, defaultPayload: [AnyHashable: Any]?) async throws {
        if let setPusherErrorToThrow {
            throw setPusherErrorToThrow
        }
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
    
    func mediaSourceForURLString(_ urlString: String) -> ElementX.MediaSourceProxy {
        MediaSourceProxy(urlString: "")
    }
    
    func loadMediaContentForSource(_ source: ElementX.MediaSourceProxy) async throws -> Data {
        Data()
    }
    
    func loadMediaThumbnailForSource(_ source: ElementX.MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        Data()
    }
}
