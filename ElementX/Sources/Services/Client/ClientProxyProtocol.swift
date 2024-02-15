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
    
    var isSyncUpdate: Bool {
        if case .receivedSyncUpdate = self {
            return true
        } else {
            return false
        }
    }
}

enum ClientProxyLoadingState {
    case loading
    case notLoading
}

enum ClientProxyError: Error {
    case failedCreatingRoom
    case failedRetrievingDirectRoom
    case failedRetrievingUserDisplayName
    case failedRetrievingUserAvatarURL
    case failedSettingUserDisplayName
    case failedRetrievingSessionVerificationController
    case failedLoadingMedia
    case mediaFileError
    case failedUploadingMedia(MatrixErrorCode)
    case failedSearchingUsers
    case failedGettingUserProfile
    case failedSettingUserAvatar
    case failedCheckingIsLastDevice(Error?)
}

enum SlidingSyncConstants {
    static let defaultTimelineLimit: UInt = 20
    static let maximumVisibleRangeSize = 30
}

/// This struct represents the configuration that we are using to register the application through Pusher to Sygnal
/// using the Matrix Rust SDK, more info here:
/// https://github.com/matrix-org/sygnal
struct PusherConfiguration {
    let identifiers: PusherIdentifiers
    let kind: PusherKind
    let appDisplayName: String
    let deviceDisplayName: String
    let profileTag: String?
    let lang: String
}

protocol ClientProxyProtocol: AnyObject, MediaLoaderProtocol {
    var callbacks: PassthroughSubject<ClientProxyCallback, Never> { get }
    
    var loadingStatePublisher: CurrentValuePublisher<ClientProxyLoadingState, Never> { get }
    
    var userID: String { get }

    var deviceID: String? { get }

    var homeserver: String { get }
        
    var userDisplayName: CurrentValuePublisher<String?, Never> { get }

    var userAvatarURL: CurrentValuePublisher<URL?, Never> { get }
    
    var pusherNotificationClientIdentifier: String? { get }
    
    var roomSummaryProvider: RoomSummaryProviderProtocol? { get }
    
    /// Used for listing rooms that shouldn't be affected by the main `roomSummaryProvider` filtering
    var alternateRoomSummaryProvider: RoomSummaryProviderProtocol? { get }
    
    var inviteSummaryProvider: RoomSummaryProviderProtocol? { get }
    
    var notificationSettings: NotificationSettingsProxyProtocol { get }
    
    var secureBackupController: SecureBackupControllerProtocol { get }
    
    func isOnlyDeviceLeft() async -> Result<Bool, ClientProxyError>
    
    func startSync()

    func stopSync()
    
    func accountURL(action: AccountManagementAction) -> URL?
    
    func directRoomForUserID(_ userID: String) async -> Result<String?, ClientProxyError>
    
    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError>
    
    func createRoom(name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?) async -> Result<String, ClientProxyError>
    
    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError>
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol?
    
    @discardableResult func loadUserDisplayName() async -> Result<Void, ClientProxyError>
    
    func setUserDisplayName(_ name: String) async -> Result<Void, ClientProxyError>

    @discardableResult func loadUserAvatarURL() async -> Result<Void, ClientProxyError>
    
    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError>
    
    func removeUserAvatar() async -> Result<Void, ClientProxyError>
        
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError>

    func logout() async -> URL?

    func setPusher(with configuration: PusherConfiguration) async throws
    
    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError>
    
    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError>
}
