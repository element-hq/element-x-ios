//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

enum ClientProxyAction {
    case receivedSyncUpdate
    case receivedAuthError(isSoftLogout: Bool)
    case receivedDecryptionError(UnableToDecryptInfo)
    
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
    case sdkError(Error)
    
    case invalidMedia
    case invalidServerName
    case failedUploadingMedia(Error, MatrixErrorCode)
    case roomPreviewIsPrivate
}

enum SlidingSyncConstants {
    static let defaultTimelineLimit: UInt32 = 20
    static let maximumVisibleRangeSize = 30
    static let defaultRequiredState = [
        RequiredState(key: "m.room.name", value: ""),
        RequiredState(key: "m.room.topic", value: ""),
        RequiredState(key: "m.room.avatar", value: ""),
        RequiredState(key: "m.room.canonical_alias", value: ""),
        RequiredState(key: "m.room.join_rules", value: ""),
        RequiredState(key: "m.room.pinned_events", value: "")
    ]
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

enum SessionVerificationState {
    case unknown
    case verified
    case unverified
}

struct RoomPreviewDetails {
    let roomID: String
    let name: String?
    let canonicalAlias: String?
    let topic: String?
    let avatarURL: URL?
    let memberCount: UInt
    let isHistoryWorldReadable: Bool
    let isJoined: Bool
    let isInvited: Bool
    let isPublic: Bool
    let canKnock: Bool
}

// sourcery: AutoMockable
protocol ClientProxyProtocol: AnyObject, MediaLoaderProtocol {
    var actionsPublisher: AnyPublisher<ClientProxyAction, Never> { get }
    
    var loadingStatePublisher: CurrentValuePublisher<ClientProxyLoadingState, Never> { get }
    
    var verificationStatePublisher: CurrentValuePublisher<SessionVerificationState, Never> { get }
    
    var userID: String { get }

    var deviceID: String? { get }

    var homeserver: String { get }
    
    var slidingSyncVersion: SlidingSyncVersion { get }
    var availableSlidingSyncVersions: [SlidingSyncVersion] { get async }
    
    var canDeactivateAccount: Bool { get }
    
    var userIDServerName: String? { get }
    
    var userDisplayNamePublisher: CurrentValuePublisher<String?, Never> { get }

    var userAvatarURLPublisher: CurrentValuePublisher<URL?, Never> { get }

    /// We delay fetching this until after the first sync. Nil until then
    var ignoredUsersPublisher: CurrentValuePublisher<[String]?, Never> { get }
    
    var pusherNotificationClientIdentifier: String? { get }
    
    var roomSummaryProvider: RoomSummaryProviderProtocol? { get }
    
    var roomsToAwait: Set<String> { get set }
    
    /// Used for listing rooms that shouldn't be affected by the main `roomSummaryProvider` filtering
    var alternateRoomSummaryProvider: RoomSummaryProviderProtocol? { get }
    
    var notificationSettings: NotificationSettingsProxyProtocol { get }
    
    var secureBackupController: SecureBackupControllerProtocol { get }
    
    func isOnlyDeviceLeft() async -> Result<Bool, ClientProxyError>
    
    func startSync()

    func stopSync()
    
    func accountURL(action: AccountManagementAction) async -> URL?
    
    func createDirectRoomIfNeeded(with userID: String, expectedRoomName: String?) async -> Result<(roomID: String, isNewRoom: Bool), ClientProxyError>
    
    func directRoomForUserID(_ userID: String) async -> Result<String?, ClientProxyError>
    
    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError>
    
    func createRoom(name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?) async -> Result<String, ClientProxyError>
    
    func joinRoom(_ roomID: String, via: [String]) async -> Result<Void, ClientProxyError>
    
    func joinRoomAlias(_ roomAlias: String) async -> Result<Void, ClientProxyError>
    
    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError>
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyType?
    
    func roomPreviewForIdentifier(_ identifier: String, via: [String]) async -> Result<RoomPreviewDetails, ClientProxyError>
    
    @discardableResult func loadUserDisplayName() async -> Result<Void, ClientProxyError>
    
    func setUserDisplayName(_ name: String) async -> Result<Void, ClientProxyError>

    @discardableResult func loadUserAvatarURL() async -> Result<Void, ClientProxyError>
    
    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError>
    
    func removeUserAvatar() async -> Result<Void, ClientProxyError>
        
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError>

    func deactivateAccount(password: String?, eraseData: Bool) async -> Result<Void, ClientProxyError>
    
    func logout() async -> URL?

    func setPusher(with configuration: PusherConfiguration) async throws
    
    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError>
    
    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError>
    
    func roomDirectorySearchProxy() -> RoomDirectorySearchProxyProtocol
    
    func resolveRoomAlias(_ alias: String) async -> Result<ResolvedRoomAlias, ClientProxyError>
    
    func getElementWellKnown() async -> Result<ElementWellKnown?, ClientProxyError>

    // MARK: - Ignored users
    
    func ignoreUser(_ userID: String) async -> Result<Void, ClientProxyError>
    
    func unignoreUser(_ userID: String) async -> Result<Void, ClientProxyError>
    
    // MARK: - Recently visited rooms
    
    func trackRecentlyVisitedRoom(_ roomID: String) async -> Result<Void, ClientProxyError>
    
    func recentlyVisitedRooms() async -> Result<[String], ClientProxyError>
    
    func recentConversationCounterparts() async -> [UserProfileProxy]
    
    // MARK: - Crypto
    
    func ed25519Base64() async -> String?
    func curve25519Base64() async -> String?
    
    func resetIdentity() async -> Result<IdentityResetHandle?, ClientProxyError>
}
