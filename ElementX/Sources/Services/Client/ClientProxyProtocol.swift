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
}

enum ClientProxyError: Error {
    case failedRetrievingDisplayName
    case failedRetrievingAccountData
    case failedSettingAccountData
    case failedRetrievingSessionVerificationController
    case failedLoadingMedia
}

enum SlidingSyncConstants {
    static let initialTimelineLimit: UInt = 0
    static let lastMessageTimelineLimit: UInt = 1
    static let timelinePrecachingTimelineLimit: UInt = 20
}

struct Pusher {
    let identifiers: PusherIdentifiers
    let kind: PusherKind
    let appDisplayName: String
    let deviceDisplayName: String
    let profileTag: String?
    let lang: String
}

protocol ClientProxyProtocol: AnyObject, MediaLoaderProtocol {
    var callbacks: PassthroughSubject<ClientProxyCallback, Never> { get }
    
    var userID: String { get }

    var deviceId: String? { get }

    var homeserver: String { get }

    var avatarURLPublisher: AnyPublisher<URL?, Never> { get }

    var restorationToken: RestorationToken? { get }
    
    var visibleRoomsSummaryProvider: RoomSummaryProviderProtocol? { get }
    
    var allRoomsSummaryProvider: RoomSummaryProviderProtocol? { get }
    
    func startSync()
    
    func stopSync()
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol?
    
    func loadUserDisplayName() async -> Result<String, ClientProxyError>

    func loadUserAvatarURL() async

    func accountDataEvent<Content: Decodable>(type: String) async -> Result<Content?, ClientProxyError>
    
    func setAccountData<Content: Encodable>(content: Content, type: String) async -> Result<Void, ClientProxyError>
    
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError>

    func logout() async

    func setPusher(_ pusher: Pusher) async throws
}
