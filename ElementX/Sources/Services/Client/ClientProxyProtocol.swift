//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    case failedRetrievingUserIdentity
    case failedResolvingRoomAlias
}

enum SlidingSyncConstants {
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

enum SessionVerificationState {
    case unknown
    case verified
    case unverified
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
    
    var sessionVerificationController: SessionVerificationControllerProxyProtocol? { get }
    
    func isOnlyDeviceLeft() async -> Result<Bool, ClientProxyError>
    
    func startSync()

    func stopSync()
    func stopSync(completion: (() -> Void)?) // Hopefully this will become async once we get SE-0371.
    
    func accountURL(action: AccountManagementAction) async -> URL?
    
    func createDirectRoomIfNeeded(with userID: String, expectedRoomName: String?) async -> Result<(roomID: String, isNewRoom: Bool), ClientProxyError>
    
    func directRoomForUserID(_ userID: String) async -> Result<String?, ClientProxyError>
    
    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError>
    
    // swiftlint:disable:next function_parameter_count
    func createRoom(name: String,
                    topic: String?,
                    isRoomPrivate: Bool,
                    isKnockingOnly: Bool,
                    userIDs: [String],
                    avatarURL: URL?,
                    aliasLocalPart: String?) async -> Result<String, ClientProxyError>
    
    func joinRoom(_ roomID: String, via: [String]) async -> Result<Void, ClientProxyError>
    
    func joinRoomAlias(_ roomAlias: String) async -> Result<Void, ClientProxyError>
    
    func knockRoom(_ roomID: String, via: [String], message: String?) async -> Result<Void, ClientProxyError>
    
    func knockRoomAlias(_ roomAlias: String, message: String?) async -> Result<Void, ClientProxyError>
    
    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError>
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyType?
    
    func roomPreviewForIdentifier(_ identifier: String, via: [String]) async -> Result<RoomPreviewProxyProtocol, ClientProxyError>
    
    @discardableResult func loadUserDisplayName() async -> Result<Void, ClientProxyError>
    
    func setUserDisplayName(_ name: String) async -> Result<Void, ClientProxyError>

    @discardableResult func loadUserAvatarURL() async -> Result<Void, ClientProxyError>
    
    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError>
    
    func removeUserAvatar() async -> Result<Void, ClientProxyError>

    func deactivateAccount(password: String?, eraseData: Bool) async -> Result<Void, ClientProxyError>
    
    func logout() async -> URL?

    func setPusher(with configuration: PusherConfiguration) async throws
    
    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError>
    
    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError>
    
    func roomDirectorySearchProxy() -> RoomDirectorySearchProxyProtocol
    
    func resolveRoomAlias(_ alias: String) async -> Result<ResolvedRoomAlias, ClientProxyError>
    
    func isAliasAvailable(_ alias: String) async -> Result<Bool, ClientProxyError>
    
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
    
    func pinUserIdentity(_ userID: String) async -> Result<Void, ClientProxyError>
    func withdrawUserIdentityVerification(_ userID: String) async -> Result<Void, ClientProxyError>
    func resetIdentity() async -> Result<IdentityResetHandle?, ClientProxyError>
    
    func userIdentity(for userID: String) async -> Result<UserIdentity?, ClientProxyError>
}
