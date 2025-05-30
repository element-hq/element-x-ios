//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import CryptoKit
import Foundation
import OrderedCollections

import MatrixRustSDK

class ClientProxy: ClientProxyProtocol {
    private let client: ClientProtocol
    private let networkMonitor: NetworkMonitorProtocol
    private let appSettings: AppSettings
    
    private let mediaLoader: MediaLoaderProtocol
    private let clientQueue: DispatchQueue
    
    private var roomListService: RoomListService
    // periphery: ignore - only for retain
    private var roomListStateUpdateTaskHandle: TaskHandle?
    // periphery: ignore - only for retain
    private var roomListStateLoadingStateUpdateTaskHandle: TaskHandle?

    private var syncService: SyncService
    // periphery: ignore - only for retain
    private var syncServiceStateUpdateTaskHandle: TaskHandle?
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var ignoredUsersListenerTaskHandle: TaskHandle?
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var verificationStateListenerTaskHandle: TaskHandle?
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var sendQueueListenerTaskHandle: TaskHandle?
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var mediaPreviewConfigListenerTaskHandle: TaskHandle?
    
    private var delegateHandle: TaskHandle?
    
    // These following summary providers both operate on the same allRooms() list but
    // can apply their own filtering and pagination
    private(set) var roomSummaryProvider: RoomSummaryProviderProtocol
    private(set) var alternateRoomSummaryProvider: RoomSummaryProviderProtocol
    
    private(set) var staticRoomSummaryProvider: StaticRoomSummaryProviderProtocol
    
    let notificationSettings: NotificationSettingsProxyProtocol

    let secureBackupController: SecureBackupControllerProtocol
    
    private(set) var sessionVerificationController: SessionVerificationControllerProxyProtocol?
    
    private static var roomCreationPowerLevelOverrides: PowerLevels {
        .init(usersDefault: nil,
              eventsDefault: nil,
              stateDefault: nil,
              ban: nil,
              kick: nil,
              redact: nil,
              invite: nil,
              notifications: nil,
              users: [:],
              events: [
                  "m.call.member": Int32(0),
                  "org.matrix.msc3401.call.member": Int32(0)
              ])
    }
    
    private static var knockingRoomCreationPowerLevelOverrides: PowerLevels {
        .init(usersDefault: nil,
              eventsDefault: nil,
              stateDefault: nil,
              ban: nil,
              kick: nil,
              redact: nil,
              invite: Int32(50),
              notifications: nil,
              users: [:],
              events: [
                  "m.call.member": Int32(0),
                  "org.matrix.msc3401.call.member": Int32(0)
              ])
    }

    private var loadCachedAvatarURLTask: Task<Void, Never>?
    private let userAvatarURLSubject = CurrentValueSubject<URL?, Never>(nil)
    var userAvatarURLPublisher: CurrentValuePublisher<URL?, Never> {
        userAvatarURLSubject.asCurrentValuePublisher()
    }
    
    private let userDisplayNameSubject = CurrentValueSubject<String?, Never>(nil)
    var userDisplayNamePublisher: CurrentValuePublisher<String?, Never> {
        userDisplayNameSubject.asCurrentValuePublisher()
    }
    
    private let ignoredUsersSubject = CurrentValueSubject<[String]?, Never>(nil)
    var ignoredUsersPublisher: CurrentValuePublisher<[String]?, Never> {
        ignoredUsersSubject
            .asCurrentValuePublisher()
    }
    
    private let userRewardsSubject = CurrentValueSubject<ZeroRewards, Never>(ZeroRewards.empty())
    var userRewardsPublisher: CurrentValuePublisher<ZeroRewards, Never> {
        userRewardsSubject.asCurrentValuePublisher()
    }
    
    private let showNewUserRewardsIntimationSubject = CurrentValueSubject<Bool, Never>(false)
    var showNewUserRewardsIntimationPublisher: CurrentValuePublisher<Bool, Never> {
        showNewUserRewardsIntimationSubject.asCurrentValuePublisher()
    }
    
    private let primaryZeroIdSubject = CurrentValueSubject<String?, Never>(nil)
    var primaryZeroId: CurrentValuePublisher<String?, Never> {
        primaryZeroIdSubject.asCurrentValuePublisher()
    }
    
    private let zeroMessengerInviteSubject = CurrentValueSubject<ZeroMessengerInvite, Never>(ZeroMessengerInvite.empty())
    var messengerInvitePublisher: CurrentValuePublisher<ZeroMessengerInvite, Never> {
        zeroMessengerInviteSubject.asCurrentValuePublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    /// Will be `true` whilst the app cleans up and forces a logout. Prevents the sync service from restarting
    /// before the client is released which ends up running in a loop. This is a workaround until the sync service
    /// can tell us *what* error occurred so we can handle restarts more gracefully.
    private var hasEncounteredAuthError = false
    
    deinit {
        stopSync { [delegateHandle] in
            // The delegate handle needs to be cancelled always after the sync stops
            delegateHandle?.cancel()
        }
    }
    
    private let actionsSubject = PassthroughSubject<ClientProxyAction, Never>()
    var actionsPublisher: AnyPublisher<ClientProxyAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private let loadingStateSubject = CurrentValueSubject<ClientProxyLoadingState, Never>(.notLoading)
    var loadingStatePublisher: CurrentValuePublisher<ClientProxyLoadingState, Never> {
        loadingStateSubject.asCurrentValuePublisher()
    }
    
    private let verificationStateSubject = CurrentValueSubject<SessionVerificationState, Never>(.unknown)
    var verificationStatePublisher: CurrentValuePublisher<SessionVerificationState, Never> {
        verificationStateSubject.asCurrentValuePublisher()
    }
    
    private let timelineMediaVisibilitySubject = CurrentValueSubject<TimelineMediaVisibility, Never>(.always)
    var timelineMediaVisibilityPublisher: CurrentValuePublisher<TimelineMediaVisibility, Never> {
        timelineMediaVisibilitySubject.asCurrentValuePublisher()
    }
    
    private let hideInviteAvatarsSubject = CurrentValueSubject<Bool, Never>(false)
    var hideInviteAvatarsPublisher: CurrentValuePublisher<Bool, Never> {
        hideInviteAvatarsSubject.asCurrentValuePublisher()
    }
    
    private let directMemberZeroProfileSubject = CurrentValueSubject<ZMatrixUser?, Never>(nil)
    var directMemberZeroProfilePublisher: CurrentValuePublisher<ZMatrixUser?, Never> {
        directMemberZeroProfileSubject.asCurrentValuePublisher()
    }
    
    private let zeroCurrentUserSubject = CurrentValueSubject<ZCurrentUser, Never>(ZCurrentUser.placeholder)
    var zeroCurrentUserPublisher: CurrentValuePublisher<ZCurrentUser, Never> {
        zeroCurrentUserSubject.asCurrentValuePublisher()
    }
    
    var roomsToAwait: Set<String> = []
    
    private let sendQueueStatusSubject = CurrentValueSubject<Bool, Never>(false)
    
    private let zeroApiProxy: ZeroApiProxyProtocol
    
    private var roomNotificationModeUpdateProtocol: RoomNotificationModeUpdatedProtocol? = nil
    
    init(client: ClientProtocol,
         needsSlidingSyncMigration: Bool,
         networkMonitor: NetworkMonitorProtocol,
         appSettings: AppSettings) async throws {
        self.client = client
        self.networkMonitor = networkMonitor
        self.appSettings = appSettings
        
        clientQueue = .init(label: "ClientProxyQueue", attributes: .concurrent)
        
        mediaLoader = MediaLoader(client: client)
        
        notificationSettings = await NotificationSettingsProxy(notificationSettings: client.getNotificationSettings())
        
        secureBackupController = SecureBackupController(encryption: client.encryption())
        
        zeroApiProxy = ZeroApiProxy(client: client, appSettings: appSettings)
        
        self.needsSlidingSyncMigration = needsSlidingSyncMigration
        
        let configuredAppService = try await ClientProxyServices(client: client,
                                                                 actionsSubject: actionsSubject,
                                                                 notificationSettings: notificationSettings,
                                                                 appSettings: appSettings,
                                                                 zeroApiProxy: zeroApiProxy)
        
        syncService = configuredAppService.syncService
        roomListService = configuredAppService.roomListService
        roomSummaryProvider = configuredAppService.roomSummaryProvider
        alternateRoomSummaryProvider = configuredAppService.alternateRoomSummaryProvider
        staticRoomSummaryProvider = configuredAppService.staticRoomSummaryProvider
        
        syncServiceStateUpdateTaskHandle = createSyncServiceStateObserver(syncService)
        roomListStateUpdateTaskHandle = createRoomListServiceObserver(roomListService)
        roomListStateLoadingStateUpdateTaskHandle = createRoomListLoadingStateUpdateObserver(roomListService)
                
        delegateHandle = try client.setDelegate(delegate: ClientDelegateWrapper { [weak self] isSoftLogout in
            self?.hasEncounteredAuthError = true
            self?.actionsSubject.send(.receivedAuthError(isSoftLogout: isSoftLogout))
        })
        
        try await client.setUtdDelegate(utdDelegate: ClientDecryptionErrorDelegate(actionsSubject: actionsSubject))
        
        networkMonitor.reachabilityPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reachability in
                if reachability == .reachable {
                    self?.startSync()
                }
            }
            .store(in: &cancellables)

        loadUserAvatarURLFromCache()
        
        ignoredUsersListenerTaskHandle = client.subscribeToIgnoredUsers(listener: IgnoredUsersListenerProxy { [weak self] ignoredUsers in
            self?.ignoredUsersSubject.send(ignoredUsers)
        })
        
        await updateVerificationState(client.encryption().verificationState())
        
        verificationStateListenerTaskHandle = client.encryption().verificationStateListener(listener: SDKListener { [weak self] verificationState in
            Task { await self?.updateVerificationState(verificationState) }
        })
        
        sendQueueListenerTaskHandle = client.subscribeToSendQueueStatus(listener: SendQueueRoomErrorListenerProxy { [weak self] roomID, error in
            MXLog.error("Send queue failed in room: \(roomID) with error: \(error)")
            self?.sendQueueStatusSubject.send(false)
        })
        
        sendQueueStatusSubject
            .combineLatest(networkMonitor.reachabilityPublisher)
            .debounce(for: 1.0, scheduler: DispatchQueue.main)
            .sink { enabled, reachability in
                MXLog.info("Send queue status changed to enabled: \(enabled), reachability: \(reachability)")
                
                if enabled == false, reachability == .reachable {
                    MXLog.info("Enabling all send queues")
                    Task {
                        await client.enableAllSendQueues(enable: true)
                    }
                }
            }
            .store(in: &cancellables)
        
        Task {
            do {
                try await client.setMediaRetentionPolicy(policy: .init(maxCacheSize: nil,
                                                                       maxFileSize: nil,
                                                                       // 30 days in seconds
                                                                       lastAccessExpiry: 30 * 24 * 60 * 60,
                                                                       // 1 day in seconds
                                                                       cleanupFrequency: 24 * 60 * 60))
            } catch {
                MXLog.error("Failed setting media retention policy with error: \(error)")
            }
        }
        
        Task {
            mediaPreviewConfigListenerTaskHandle = await createMediaPreviewConfigObserver()
        }
        
        _ = await loadZeroMessengerInvite()
    }
    
    var userID: String {
        do {
            return try client.userId()
        } catch {
            MXLog.error("Failed retrieving room info with error: \(error)")
            return "Unknown user identifier"
        }
    }

    var deviceID: String? {
        do {
            return try client.deviceId()
        } catch {
            MXLog.error("Failed retrieving deviceID with error: \(error)")
            return nil
        }
    }

    var homeserver: String {
        client.homeserver()
    }
    
    let needsSlidingSyncMigration: Bool
    var slidingSyncVersion: SlidingSyncVersion {
        client.slidingSyncVersion()
    }
    
    var canDeactivateAccount: Bool {
        client.canDeactivateAccount()
    }
    
    var userIDServerName: String? {
        do {
            return try client.userIdServerName()
        } catch {
            MXLog.error("Failed retrieving userID server name with error: \(error)")
            return nil
        }
    }
    
    var isReportRoomSupported: Bool {
        get async {
            do {
                return try await client.isReportRoomApiSupported()
            } catch {
                MXLog.error("Failed checking report room support with error: \(error)")
                return false
            }
        }
    }

    private(set) lazy var pusherNotificationClientIdentifier: String? = {
        // NOTE: The result is stored as part of the restoration token. Any changes
        // here would require a migration to correctly match incoming notifications.
        guard let data = userID.data(using: .utf8) else { return nil }
        let digest = SHA256.hash(data: data)
        return digest.compactMap { String(format: "%02x", $0) }.joined()
    }()
    
    func isOnlyDeviceLeft() async -> Result<Bool, ClientProxyError> {
        do {
            let result = try await client.encryption().isLastDevice()
            return .success(result)
        } catch {
            MXLog.error("Failed checking isLastDevice with error: \(error)")
            return .failure(.sdkError(error))
        }
    }

    func startSync() {
        guard !needsSlidingSyncMigration else {
            MXLog.warning("Ignoring request, this client needs to be migrated to native sliding sync.")
            return
        }
        
        guard !hasEncounteredAuthError else {
            MXLog.warning("Ignoring request, this client has an unknown token.")
            return
        }
        
        guard networkMonitor.reachabilityPublisher.value == .reachable else {
            MXLog.warning("Ignoring request, network unreachable.")
            return
        }
        
        MXLog.info("Starting sync")
        
        Task {
            await syncService.start()
            
            // If we are using OIDC we want to cache the account management URL in volatile memory on the SDK side.
            // To avoid the cache being invalidated while the app is backgrounded, we cache at every sync start.
            await cacheAccountURL()
        }
    }
    
    /// A stored task for restarting the sync after a failure. This is stored so that we can cancel
    /// it when `stopSync` is called (e.g. when signing out) to prevent an otherwise infinite
    /// loop that was triggered by trying to sync a signed out session.
    @CancellableTask private var restartTask: Task<Void, Never>?
    
    func restartSync() {
        guard restartTask == nil else { return }
        
        restartTask = Task { [weak self] in
            do {
                // Until the SDK can tell us the failure, we add a small
                // delay to avoid generating multi-gigabyte log files.
                try await Task.sleep(for: .milliseconds(250))
                self?.startSync()
            } catch {
                MXLog.error("Restart cancelled.")
            }
            self?.restartTask = nil
        }
    }
    
    func stopSync() {
        stopSync(completion: nil)
    }
    
    func stopSync(completion: (() -> Void)?) {
        MXLog.info("Stopping sync")
        
        if restartTask != nil {
            MXLog.warning("Removing the sync service restart task.")
            restartTask = nil
        }
        
        // Capture the sync service strongly as this method is called on deinit and so the
        // existence of self when the Task executes is questionable and would sometimes crash.
        // Note: This isn't strictly necessary now given the unwrap above, but leaving the code as
        // documentation. SE-0371 will allow us to fix this by using an async deinit.
        Task { [syncService] in
            defer {
                completion?()
            }
            
            await syncService.stop()
            MXLog.info("Sync stopped")
        }
    }
    
    func accountURL(action: AccountManagementAction) async -> URL? {
        try? await client.accountUrl(action: action).flatMap(URL.init(string:))
    }
    
    func directRoomForUserID(_ userID: String) -> Result<String?, ClientProxyError> {
        do {
            let room = self.client.rooms().first(where: {
                $0.heroes().count == 1 && $0.heroes().first?.userId == userID
            })
            // let roomID = try self.client.getDmRoom(userId: userID)?.id()
            return .success(room?.id())
        } catch {
            MXLog.error("Failed retrieving direct room for userID: \(userID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError> {
        do {
            let parameters = CreateRoomParameters(name: nil,
                                                  topic: nil,
                                                  isEncrypted: true,
                                                  isDirect: true,
                                                  visibility: .private,
                                                  preset: .trustedPrivateChat,
                                                  invite: [userID],
                                                  avatar: nil,
                                                  powerLevelContentOverride: Self.roomCreationPowerLevelOverrides)
            let roomID = try await client.createRoom(request: parameters)
            
            await waitForRoomToSync(roomID: roomID)
            
            return .success(roomID)
        } catch {
            MXLog.error("Failed creating direct room for userID: \(userID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func createRoom(name: String,
                    topic: String?,
                    isRoomPrivate: Bool,
                    isKnockingOnly: Bool,
                    userIDs: [String],
                    avatarURL: URL?,
                    aliasLocalPart: String?) async -> Result<String, ClientProxyError> {
        do {
            let parameters = CreateRoomParameters(name: name,
                                                  topic: topic,
                                                  isEncrypted: isRoomPrivate,
                                                  isDirect: false,
                                                  visibility: isRoomPrivate ? .private : .public,
                                                  preset: isRoomPrivate ? .privateChat : .publicChat,
                                                  invite: userIDs,
                                                  avatar: avatarURL?.absoluteString,
                                                  powerLevelContentOverride: isKnockingOnly ? Self.knockingRoomCreationPowerLevelOverrides : Self.roomCreationPowerLevelOverrides,
                                                  joinRuleOverride: isKnockingOnly ? .knock : nil,
                                                  historyVisibilityOverride: isRoomPrivate ? .invited : nil,
                                                  // This is an FFI naming mistake, what is required is the `aliasLocalPart` not the whole alias
                                                  canonicalAlias: aliasLocalPart)
            let roomID = try await client.createRoom(request: parameters)
            
            await waitForRoomToSync(roomID: roomID)
            
            return .success(roomID)
        } catch {
            MXLog.error("Failed creating room with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func joinRoom(_ roomID: String, via: [String]) async -> Result<Void, ClientProxyError> {
        do {
            let _ = try await client.joinRoomByIdOrAlias(roomIdOrAlias: roomID, serverNames: via)
                        
            await waitForRoomToSync(roomID: roomID, timeout: .seconds(30))
            
            return .success(())
        } catch ClientError.MatrixApi(.forbidden, _, _, _) {
            MXLog.error("Failed joining roomAlias: \(roomID) forbidden")
            return .failure(.forbiddenAccess)
        } catch {
            MXLog.error("Failed joining roomID: \(roomID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func joinRoomAlias(_ roomAlias: String) async -> Result<Void, ClientProxyError> {
        do {
            let room = try await client.joinRoomByIdOrAlias(roomIdOrAlias: roomAlias, serverNames: [])
            
            await waitForRoomToSync(roomID: room.id(), timeout: .seconds(30))
            
            return .success(())
        } catch ClientError.MatrixApi(.forbidden, _, _, _) {
            MXLog.error("Failed joining roomAlias: \(roomAlias) forbidden")
            return .failure(.forbiddenAccess)
        } catch {
            MXLog.error("Failed joining roomAlias: \(roomAlias) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func knockRoom(_ roomID: String, via: [String], message: String?) async -> Result<Void, ClientProxyError> {
        do {
            let _ = try await client.knock(roomIdOrAlias: roomID, reason: message, serverNames: via)
            await waitForRoomToSync(roomID: roomID, timeout: .seconds(30))
            return .success(())
        } catch {
            MXLog.error("Failed knocking roomID: \(roomID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func knockRoomAlias(_ roomAlias: String, message: String?) async -> Result<Void, ClientProxyError> {
        do {
            let room = try await client.knock(roomIdOrAlias: roomAlias, reason: message, serverNames: [])
            await waitForRoomToSync(roomID: room.id(), timeout: .seconds(30))
            return .success(())
        } catch {
            MXLog.error("Failed knocking roomAlias: \(roomAlias) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError> {
        guard let mimeType = media.mimeType else {
            MXLog.error("Failed uploading media, invalid mime type: \(media)")
            return .failure(ClientProxyError.invalidMedia)
        }
        
        do {
            let data = try Data(contentsOf: media.url)
            let matrixUrl = try await client.uploadMedia(mimeType: mimeType, data: data, progressWatcher: nil)
            return .success(matrixUrl)
        } catch let ClientError.MatrixApi(errorKind, _, _, _) {
            MXLog.error("Failed uploading media with error kind: \(errorKind)")
            return .failure(ClientProxyError.failedUploadingMedia(errorKind))
        } catch {
            MXLog.error("Failed uploading media with error: \(error)")
            return .failure(ClientProxyError.sdkError(error))
        }
    }
        
    func roomForIdentifier(_ identifier: String) async -> RoomProxyType? {
        let shouldAwait = roomsToAwait.remove(identifier) != nil
        
        // Try fetching the room from the cold cache (if available) first
        if let room = await buildRoomForIdentifier(identifier) {
            return room
        }
        
        if !roomSummaryProvider.statePublisher.value.isLoaded {
            _ = await roomSummaryProvider.statePublisher.values.first { $0.isLoaded }
        }
        
        if shouldAwait {
            await waitForRoomToSync(roomID: identifier)
        }
        
        return await buildRoomForIdentifier(identifier)
    }
    
    func leaveRoom(_ roomID: String) async -> Result<Void, ClientProxyError> {
        do {
            let roomListItem = try roomListService.room(roomId: roomID)
            let invitedRoomPreview = try await roomListItem.previewRoom(via: [])
            try await invitedRoomPreview.leave()
            return .success(())
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func roomPreviewForIdentifier(_ identifier: String, via: [String]) async -> Result<RoomPreviewProxyProtocol, ClientProxyError> {
        do {
            let roomPreview = try await client.getRoomPreviewFromRoomId(roomId: identifier, viaServers: via)
            return try .success(RoomPreviewProxy(roomId: identifier, roomPreview: roomPreview, zeroUsersService: zeroApiProxy.matrixUsersService))
        } catch ClientError.MatrixApi(.forbidden, _, _, _) {
            MXLog.error("Failed retrieving preview for room: \(identifier) is private")
            return .failure(.roomPreviewIsPrivate)
        } catch {
            MXLog.error("Failed retrieving preview for room: \(identifier) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func roomSummaryForIdentifier(_ identifier: String) -> RoomSummary? {
        staticRoomSummaryProvider.roomListPublisher.value.first { $0.id == identifier }
    }
    
    func roomSummaryForAlias(_ alias: String) -> RoomSummary? {
        staticRoomSummaryProvider.roomListPublisher.value.first { $0.canonicalAlias == alias || $0.alternativeAliases.contains(alias) }
    }
    
    func reportRoomForIdentifier(_ identifier: String, reason: String?) async -> Result<Void, ClientProxyError> {
        do {
            guard let room = try client.getRoom(roomId: identifier) else {
                MXLog.error("Failed reporting room with identifier: \(identifier), room not in local store")
                return .failure(.roomNotInLocalStore)
            }
            try await room.reportRoom(reason: reason)
            return .success(())
        } catch {
            MXLog.error("Failed reporting room with identifier: \(identifier), with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func roomInfoForAlias(_ alias: String) async -> RoomInfoProxy? {
        do {
            if let resolvedRoomAlias = try await client.resolveRoomAlias(roomAlias: alias) {
                let roomId = resolvedRoomAlias.roomId
                let roomInfo = try await roomListService.room(roomId: roomId).roomInfo()
                return RoomInfoProxy(roomInfo: roomInfo, roomAvatarCached: nil)
            } else {
                return nil
            }
        } catch {
            MXLog.error("Failed to load room for alias with error: \(error)")
            return nil
        }
    }

    func loadUserDisplayName() async -> Result<Void, ClientProxyError> {
        do {
            userDisplayNameSubject.send(appSettings.zeroLoggedInUser.displayName)
            
            let displayName = try await client.displayName()
            userDisplayNameSubject.send(displayName)
            return .success(())
        } catch {
            MXLog.error("Failed loading user display name Owith error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func setUserInfo(_ name: String, primaryZId: String?) async -> Result<Void, ClientProxyError> {
        do {
            try await client.setDisplayName(name: name)
            try await zeroApiProxy.matrixUsersService.updateUserInfo(displayName: name, primaryZId: primaryZId)
            Task {
                await self.loadUserDisplayName()
                
            }
            _ = try await fetchZeroCurrentUser()
            return .success(())
        } catch {
            MXLog.error("Failed setting user display name with error: \(error)")
            return .failure(.sdkError(error))
        }
    }

    func loadUserAvatarURL() async -> Result<Void, ClientProxyError> {
        do {
            let urlString = try await client.avatarUrl()
            loadCachedAvatarURLTask?.cancel()
            userAvatarURLSubject.send(urlString.flatMap(URL.init))
            return .success(())
        } catch {
            MXLog.error("Failed loading user avatar URL with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError> {
        guard case let .image(imageURL, _, _) = media, let mimeType = media.mimeType else {
            MXLog.error("Failed uploading, invalid media: \(media)")
            return .failure(.invalidMedia)
        }
            
        do {
            let data = try Data(contentsOf: imageURL)
            try await client.uploadAvatar(mimeType: mimeType, data: data)
            Task {
                await self.loadUserAvatarURL()
            }
            Task {
                if let urlString = try await client.avatarUrl() {
                    try await zeroApiProxy.matrixUsersService.updateUserAvatar(avatarUrl: urlString)
                }
            }
            return .success(())
        } catch {
            MXLog.error("Failed setting user avatar with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func removeUserAvatar() async -> Result<Void, ClientProxyError> {
        do {
            try await client.removeAvatar()
            Task {
                await self.loadUserAvatarURL()
            }
            return .success(())
        } catch {
            MXLog.error("Failed removing user avatar with error: \(error)")
            return .failure(.sdkError(error))
        }
    }

    func logout() async {
        do {
            try await client.logout()
        } catch {
            MXLog.error("Failed logging out with error: \(error)")
        }
    }
    
    func deactivateAccount(password: String?, eraseData: Bool) async -> Result<Void, ClientProxyError> {
        do {
            try await client.deactivateAccount(authData: password.map { .password(passwordDetails: .init(identifier: userID, password: $0)) },
                                               eraseData: eraseData)
            return .success(())
        } catch {
            return .failure(.sdkError(error))
        }
    }
    
    func setPusher(with configuration: PusherConfiguration) async throws {
        try await client.setPusher(identifiers: configuration.identifiers,
                                   kind: configuration.kind,
                                   appDisplayName: configuration.appDisplayName,
                                   deviceDisplayName: configuration.deviceDisplayName,
                                   profileTag: configuration.profileTag,
                                   lang: configuration.lang)
    }
    
    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError> {
        do {
            let zeroUsers = try await zeroApiProxy.matrixUsersService.searchZeroUsers(query: searchTerm)
            let matrixUsers = try await zeroUsers.concurrentMap { zeroUser in
                let userProfile = try await self.client.getProfile(userId: zeroUser.matrixId)
                return UserProfileProxy(sdkUserProfile: userProfile, zeroUserProfile: zeroUser)
            }
            return .success(.init(results: matrixUsers, limited: false))
        } catch {
            MXLog.error("Failed searching users with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError> {
        do {
            async let sdkProfile = client.getProfile(userId: userID)
            async let zeroProfile = zeroApiProxy.matrixUsersService.fetchZeroUser(userId: userID)
            // Await both results
            let (sdkProfileResult, zeroProfileResult) = try await (sdkProfile, zeroProfile)
            return .success(.init(zeroUserProfile: zeroProfileResult, sdkUserProfile: sdkProfileResult))
        } catch {
            MXLog.error("Failed retrieving profile for userID: \(userID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func zeroProfile(userId: String) async {
        do {
            let zeroProfile = try await zeroApiProxy.matrixUsersService.fetchZeroUser(userId: userId)
            directMemberZeroProfileSubject.send(zeroProfile)
        } catch {
            MXLog.error("Failed retrieving zero profile for userID: \(userID) with error: \(error)")
        }
    }
    
    func roomDirectorySearchProxy() -> RoomDirectorySearchProxyProtocol {
        RoomDirectorySearchProxy(roomDirectorySearch: client.roomDirectorySearch(), appSettings: appSettings)
    }
    
    func resolveRoomAlias(_ alias: String) async -> Result<ResolvedRoomAlias, ClientProxyError> {
        do {
            guard let resolvedAlias = try await client.resolveRoomAlias(roomAlias: alias) else {
                MXLog.error("Failed resolving room alias, is nil")
                return .failure(.failedResolvingRoomAlias)
            }
            
            // Resolving aliases is done through the directory/room API which returns too many / all known
            // vias, which in turn results in invalid join requests. Trim them to something manageable
            // https://github.com/element-hq/synapse/issues/17298
            let limitedAlias = ResolvedRoomAlias(roomId: resolvedAlias.roomId, servers: Array(resolvedAlias.servers.prefix(50)))
            
            return .success(limitedAlias)
        } catch {
            MXLog.error("Failed resolving room alias: \(alias) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func isAliasAvailable(_ alias: String) async -> Result<Bool, ClientProxyError> {
        do {
            let result = try await client.isRoomAliasAvailable(alias: alias)
            return .success(result)
        } catch {
            MXLog.error("Failed checking if alias: \(alias) is available with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func clearCaches() async -> Result<Void, ClientProxyError> {
        do {
            return try await .success(client.clearCaches())
        } catch {
            MXLog.error("Failed clearing client caches with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func fetchMediaPreviewConfiguration() async -> Result<MediaPreviewConfig?, ClientProxyError> {
        do {
            let config = try await client.fetchMediaPreviewConfig()
            return .success(config)
        } catch {
            MXLog.error("Failed fetching media preview config with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
        
    // MARK: Ignored users
    
    func ignoreUser(_ userID: String) async -> Result<Void, ClientProxyError> {
        do {
            try await client.ignoreUser(userId: userID)
            return .success(())
        } catch {
            MXLog.error("Failed ignoring user with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func unignoreUser(_ userID: String) async -> Result<Void, ClientProxyError> {
        do {
            try await client.unignoreUser(userId: userID)
            return .success(())
        } catch {
            MXLog.error("Failed unignoring user with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    // MARK: Recently visited rooms
    
    func trackRecentlyVisitedRoom(_ roomID: String) async -> Result<Void, ClientProxyError> {
        do {
            try await client.trackRecentlyVisitedRoom(room: roomID)
            return .success(())
        } catch {
            MXLog.error("Failed tracking recently visited room: \(roomID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func recentlyVisitedRooms() async -> Result<[String], ClientProxyError> {
        do {
            let result = try await client.getRecentlyVisitedRooms()
            return .success(result)
        } catch {
            MXLog.error("Failed retrieving recently visited rooms with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func recentConversationCounterparts() async -> [UserProfileProxy] {
        let maxResultsToReturn = 5
        
        guard case let .success(roomIdentifiers) = await recentlyVisitedRooms() else {
            return []
        }
        
        var users: OrderedSet<UserProfileProxy> = []
        
        for roomID in roomIdentifiers {
            guard case let .joined(roomProxy) = await roomForIdentifier(roomID),
                  roomProxy.infoPublisher.value.isDirect,
                  let members = await roomProxy.members() else {
                continue
            }
            
            for member in members where member.isActive && member.userID != userID {
                users.append(.init(userID: member.userID, displayName: member.displayName, avatarURL: member.avatarURL))
                
                // Return early to avoid unnecessary work
                if users.count >= maxResultsToReturn {
                    return users.elements
                }
            }
        }
        
        return users.elements
    }
    
    // MARK: Moderation & Safety
    
    func setTimelineMediaVisibility(_ value: TimelineMediaVisibility) async -> Result<Void, ClientProxyError> {
        do {
            try await client.setMediaPreviewDisplayPolicy(policy: value.rustValue)
            return .success(())
        } catch {
            MXLog.error("Failed to set timeline media visibility: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func setHideInviteAvatars(_ value: Bool) async -> Result<Void, ClientProxyError> {
        do {
            try await client.setInviteAvatarsDisplayPolicy(policy: value ? .off : .on)
            return .success(())
        } catch {
            MXLog.error("Failed to set hide invite avatars: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func getUserRewards(shouldCheckRewardsIntiamtion: Bool = false) async -> Result<Void, ClientProxyError> {
        do {
            let oldRewards = appSettings.zeroRewardsCredit
            if shouldCheckRewardsIntiamtion {
                userRewardsSubject.send(oldRewards)
            }
            
            let apiRewards = try await zeroApiProxy.rewardsApi.fetchMyRewards()
            switch apiRewards {
            case .success(let zRewards):
                let apiCurrency = try await zeroApiProxy.rewardsApi.loadZeroCurrenyRate()
                switch apiCurrency {
                case .success(let zCurrency):
                    let zeroRewards = ZeroRewards(rewards: zRewards, currency: zCurrency)
                    
                    if shouldCheckRewardsIntiamtion {
                        let oldCredits = oldRewards.getZeroCredits()
                        let newCredits = zeroRewards.getZeroCredits()
                        showNewUserRewardsIntimationSubject.send(newCredits > oldCredits)
                    }
                    
                    appSettings.zeroRewardsCredit = zeroRewards
                    userRewardsSubject.send(zeroRewards)
                    return .success(())
                case .failure(let error):
                    return .failure(.zeroError(error))
                }
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func dismissRewardsIntimation() {
        Task {
            try await Task.sleep(for: .seconds(3))
            showNewUserRewardsIntimationSubject.send(false)
        }
    }
    
    func loadZeroMessengerInvite() async -> Result<Void, ClientProxyError> {
        do {
            let apiMessengerInvite = try await zeroApiProxy.messengerInviteApi.fetchMessengerInvite()
            switch apiMessengerInvite {
            case .success(let invite):
                let zeroMessengerInvite = ZeroMessengerInvite(messengerInvite: invite)
                zeroMessengerInviteSubject.send(zeroMessengerInvite)
                return .success(())
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func isProfileCompletionRequired() async -> Bool {
        do {
            let currentUser = try await zeroApiProxy.matrixUsersService.fetchCurrentUser()
            if let user = currentUser {
                return user.displayName.isEmpty || user.displayName.stringMatchesUserIdFormatRegex()
            } else {
                return false
            }
        } catch {
            MXLog.error(error)
            return false
        }
    }
    
    func completeUserAccountProfile(avatar: MediaInfo?, displayName: String, inviteCode: String) async -> Result<Void, ClientProxyError> {
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                group.addTask {
                    if let localMedia = avatar {
                        try await self.setUserAvatar(media: localMedia).get()
                    }
                }
                group.addTask {
                    try await self.setUserInfo(displayName, primaryZId: nil).get()
                }
                try await group.waitForAll()
            }
            let userId = try client.userId().matrixIdToCleanHex()
            let avatarUrl = try await client.avatarUrl() ?? ""
            let result = try await zeroApiProxy.createAccountApi
                .finaliseCreateAccount(request: ZFinaliseCreateAccount(inviteCode: inviteCode, name: displayName, userId: userId, profileImageUrl: avatarUrl))
            
            switch result {
            case .success(let user):
                /// create a room with the user who invited
                _ = await createDirectRoom(with: user.inviter.matrixId, expectedRoomName: user.inviter.displayName)
                return .success(())
                
            case .failure(let failure):
                return .failure(.failedCompletingUserProfile)
            }
        } catch {
            MXLog.error(error)
            return .failure(.failedCompletingUserProfile)
        }
    }
    
    func deleteUserAccount() async -> Result<Void, ClientProxyError> {
        do {
            let deleteAccountResult = try await zeroApiProxy.userAccountApi.deleteAccount()
            switch deleteAccountResult {
            case .success(_):
                return .success(())
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func checkAndLinkZeroUser() async {
        do {
            zeroCurrentUserSubject.send(appSettings.zeroLoggedInUser)
            guard let currentUser = try await fetchZeroCurrentUser() else { return }
            if currentUser.matrixId == nil {
                _ = try await zeroApiProxy.createAccountApi.linkMatrixUserToZero(matrixUserId: userID)
            }
            let thirdWebWalletAddress = currentUser.wallets?.first(where: { $0.isThirdWeb })
            if thirdWebWalletAddress == nil {
                _ = try await zeroApiProxy.walletsApi.initializeThirdWebWallet()
                _ = try await fetchZeroCurrentUser()
            }
        } catch {
            MXLog.error("Failed linking matrixId to zero user. Error: \(error)")
        }
    }
    
    func fetchZeroFeeds(channelZId: String?, following: Bool, limit: Int, skip: Int) async -> Result<[ZPost], ClientProxyError> {
        do {
            let zeroPostsResult = try await zeroApiProxy.postsApi.fetchPosts(channelZId: channelZId, following: following, limit: limit, skip: skip)
            switch zeroPostsResult {
            case .success(let posts):
                return .success(posts)
            case .failure(let error):
                return .failure(checkPostFetchError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func fetchFeedDetails(feedId: String) async -> Result<ZPost, ClientProxyError> {
        do {
            let zeroPostResult = try await zeroApiProxy.postsApi.fetchPostDetails(postId: feedId)
            switch zeroPostResult {
            case .success(let post):
                return .success(post)
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func fetchFeedReplies(feedId: String, limit: Int, skip: Int) async -> Result<[ZPost], ClientProxyError> {
        do {
            let zeroFeedRepliesResult = try await zeroApiProxy.postsApi.fetchPostReplies(postId: feedId, limit: limit, skip: skip)
            switch zeroFeedRepliesResult {
            case .success(let replies):
                return .success(replies)
            case .failure(let error):
                return .failure(checkPostFetchError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func addMeowsToFeed(feedId: String, amount: Int) async -> Result<ZPost, ClientProxyError> {
        do {
            let zeroAddPostMeowResult = try await zeroApiProxy.postsApi.addMeowsToPst(amount: amount, postId: feedId)
            switch zeroAddPostMeowResult {
            case .success(let post):
                return .success(post)
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func postNewFeed(channelZId: String, content: String, replyToPost: String?, mediaFile: URL?) async -> Result<Void, ClientProxyError> {
        do {
            var mediaId: String? = nil
            if let mediaFile = mediaFile {
                let uploadMediaResult = try await zeroApiProxy.metaDataApi.uploadMedia(media: mediaFile)
                switch uploadMediaResult {
                case .success(let uploadedMediaId):
                    mediaId = uploadedMediaId
                case .failure(let error):
                    return .failure(.zeroError(error))
                }
            }
            let postFeedResult = try await zeroApiProxy.postsApi.createNewPost(channelZId: channelZId,
                                                                               content: content,
                                                                               replyToPost: replyToPost,
                                                                               mediaId: mediaId)
            switch postFeedResult {
            case .success:
                return .success(())
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func fetchFeedUserProfile(userZId: String) async -> Result<ZPostUserProfile, ClientProxyError> {
        do {
            let cleanedUserZId = userZId.replacingOccurrences(of: ZeroContants.ZERO_CHANNEL_PREFIX, with: "")
            let result = try await zeroApiProxy.postUserApi.fetchUserProfile(userZId: cleanedUserZId)
            switch result {
            case .success(let profile):
                return .success(profile)
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func fetchUserFeeds(userId: String, limit: Int, skip: Int) async -> Result<[ZPost], ClientProxyError> {
        do {
            let result = try await zeroApiProxy.postsApi.fetchUserPosts(userId: userId, limit: limit, skip: skip)
            switch result {
            case .success(let feeds):
                return .success(feeds)
            case .failure(let error):
                return .failure(checkPostFetchError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func fetchFeedUserFollowingStatus(userId: String) async -> Result<ZPostUserFollowingStatus, ClientProxyError> {
        do {
            let result = try await zeroApiProxy.postUserApi.fetchUserFollowingStatus(userId: userId)
            switch result {
            case .success(let following):
                return .success(following)
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func followFeedUser(userId: String) async -> Result<Void, ClientProxyError> {
        do {
            let result = try await zeroApiProxy.postUserApi.followPostUser(userId: userId)
            switch result {
            case .success(_):
                return .success(())
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func unFollowFeedUser(userId: String) async -> Result<Void, ClientProxyError> {
        do {
            let result = try await zeroApiProxy.postUserApi.unFollowPostUser(userId: userId)
            switch result {
            case .success:
                return .success(())
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func fetchUserZIds() async -> Result<[String], ClientProxyError> {
        do {
            let zIdsResult = try await zeroApiProxy.channelsApi.fetchZeroIds()
            switch zIdsResult {
            case .success(let zIds):
                return .success(zIds)
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func joinChannel(roomAliasOrId: String) async -> Result<String, ClientProxyError> {
        do {
            let joinChannelResult = try await zeroApiProxy.channelsApi.joinChannel(roomAliasOrId: roomAliasOrId)
            switch joinChannelResult {
            case .success(let roomId):
                _ = await joinRoom(roomAliasOrId, via: [])
                return .success(roomId)
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error(error)
            return .failure(.zeroError(error))
        }
    }
    
    func initializeThirdWebWalletForUser() async -> Result<Void, ClientProxyError> {
        do {
            let result = try await zeroApiProxy.walletsApi.initializeThirdWebWallet()
            switch result {
            case .success:
                return .success(())
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error("Failed to initialize third web wallet for user: \(error)")
            return .failure(.zeroError(error))
        }
    }
    
    func getLinkPreviewMetaData(url: String) async -> Result<ZLinkPreview, ClientProxyError> {
        do {
            let result = try await zeroApiProxy.metaDataApi.getLinkPreview(url: url)
            switch result {
            case .success(let linkPreview):
                return .success(linkPreview)
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error("Failed to fetch link preview of url: \(url), with error: \(error)")
            return .failure(.zeroError(error))
        }
    }
    
    func getPostMediaInfo(mediaId: String) async -> Result<ZPostMedia, ClientProxyError> {
        do {
            let result = try await zeroApiProxy.metaDataApi.getPostMediaInfo(mediaId: mediaId)
            switch result {
            case .success(let media):
                return .success(media)
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error("Failed to fetch post media with id: \(mediaId), with error: \(error)")
            return .failure(.zeroError(error))
        }
    }
    
    func fetchYoutubeLinkMetaData(youtubrUrl: String) async -> Result<ZLinkPreview, ClientProxyError> {
        do {
            let result = try await zeroApiProxy.metaDataApi.fetchYoutubeLinkMetaData(youtubeUrl: youtubrUrl)
            switch result {
            case .success(let metaData):
                return .success(metaData)
            case .failure(let error):
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error("Failed to youtube url(\(youtubrUrl)) meta data, with error: \(error)")
            return .failure(.zeroError(error))
        }
    }
    
    // MARK: - Private
    
    private func cacheAccountURL() async {
        // Calling this function for the first time will cache the account URL in volatile memory for 24 hrs on the SDK.
        _ = try? await client.accountUrl(action: nil)
    }
    
    private func updateVerificationState(_ verificationState: VerificationState) async {
        let verificationState: SessionVerificationState = switch verificationState {
        case .unknown:
            .unknown
        case .unverified:
            .unverified
        case .verified:
            .verified
        }
        
        // The session verification controller requires the user's identity which
        // isn't available before a keys query response. Use the verification
        // state updates as an aproximation for when that happens.
        await buildSessionVerificationControllerProxyIfPossible(verificationState: verificationState)
        
        // Only update the session verification state after creating a session
        // verification proxy to avoid race conditions
        verificationStateSubject.send(verificationState)
    }
    
    private func buildSessionVerificationControllerProxyIfPossible(verificationState: SessionVerificationState) async {
        guard sessionVerificationController == nil, verificationState != .unknown else {
            return
        }
        
        do {
            let sessionVerificationController = try await client.getSessionVerificationController()
            self.sessionVerificationController = SessionVerificationControllerProxy(sessionVerificationController: sessionVerificationController)
        } catch {
            MXLog.error("Failed retrieving session verification controller proxy with error: \(error)")
        }
    }

    private func loadUserAvatarURLFromCache() {
        loadCachedAvatarURLTask = Task {
            do {
                let urlString = try await self.client.cachedAvatarUrl()
                guard !Task.isCancelled else { return }
                self.userAvatarURLSubject.value = urlString.flatMap(URL.init)
            } catch {
                MXLog.error("Failed to look for the avatar url in the cache: \(error)")
            }
        }
    }
    
    private func createSyncServiceStateObserver(_ syncService: SyncService) -> TaskHandle {
        syncService.state(listener: SDKListener { [weak self] state in
            guard let self else { return }
            
            MXLog.info("Received sync service update: \(state)")
            
            switch state {
            case .running, .terminated, .idle:
                break
            case .error:
                restartSync()
            case .offline:
                // This needs to be enabled in the client builder first to be actually used
                break
            }
        })
    }
    
    private func createMediaPreviewConfigObserver() async -> TaskHandle? {
        do {
            return try await client.subscribeToMediaPreviewConfig(listener: SDKListener { [weak self] config in
                guard let self else { return }
                
                if let config {
                    timelineMediaVisibilitySubject.send(config.mediaPreviewVisibility)
                    hideInviteAvatarsSubject.send(config.hideInviteAvatars)
                } else {
                    // return default values
                    timelineMediaVisibilitySubject.send(.always)
                    hideInviteAvatarsSubject.send(false)
                }
            })
        } catch {
            MXLog.error("Failed creating media preview config observer: \(error)")
            return nil
        }
    }

    private func createRoomListServiceObserver(_ roomListService: RoomListService) -> TaskHandle {
        roomListService.state(listener: SDKListener { [weak self] state in
            guard let self else { return }
            
            MXLog.info("Received room list update: \(state)")
            
            guard state != .error,
                  state != .terminated else {
                // The sync service is responsible of handling error and termination
                return
            }
            
            // Hide the sync spinner as soon as we get any update back
            actionsSubject.send(.receivedSyncUpdate)
            
            if ignoredUsersSubject.value == nil {
                updateIgnoredUsers()
            }
        })
    }
    
    private func createRoomListLoadingStateUpdateObserver(_ roomListService: RoomListService) -> TaskHandle {
        roomListService.syncIndicator(delayBeforeShowingInMs: 1000, delayBeforeHidingInMs: 0, listener: SDKListener { [weak self] state in
            guard let self else { return }
            
            switch state {
            case .show:
                loadingStateSubject.send(.loading)
            case .hide:
                loadingStateSubject.send(.notLoading)
            }
        })
    }
    
    private func buildRoomForIdentifier(_ roomID: String) async -> RoomProxyType? {
        do {
            guard let room = try client.getRoom(roomId: roomID) else {
                return nil
            }
            
            switch room.membership() {
            case .invited:
                return try await .invited(InvitedRoomProxy(room: room, zeroUsersService: zeroApiProxy.matrixUsersService))
            case .knocked:
                guard appSettings.knockingEnabled else {
                    return nil
                }
                
                return try await .knocked(KnockedRoomProxy(room: room, zeroUsersService: zeroApiProxy.matrixUsersService))
            case .joined:
                let roomProxy = try await JoinedRoomProxy(roomListService: roomListService,
                                                          room: room,
                                                          zeroChatApi: zeroApiProxy.chatApi,
                                                          zeroUsersService: zeroApiProxy.matrixUsersService)
                
                return .joined(roomProxy)
            case .left:
                return .left
            case .banned:
                return try await .banned(BannedRoomProxy(room: room, zeroUsersService: zeroApiProxy.matrixUsersService))
            }
        } catch {
            MXLog.error("Failed retrieving room: \(roomID), with error: \(error)")
            return nil
        }
    }
    
    private func waitForRoomToSync(roomID: String, timeout: Duration = .seconds(10)) async {
        let runner = ExpiringTaskRunner { [weak self] in
            try await self?.client.awaitRoomRemoteEcho(roomId: roomID)
        }
        
        _ = try? await runner.run(timeout: timeout)
    }

    private func updateIgnoredUsers() {
        Task {
            do {
                let ignoredUsers = try await client.ignoredUsers()
                ignoredUsersSubject.send(ignoredUsers)
            } catch {
                MXLog.error("Failed fetching ignored users with error: \(error)")
            }
        }
    }
    
    private func checkPostFetchError(_ error: Error) -> ClientProxyError {
        let postLimitReachedError = "The data couldn’t be read because it is missing."
        if error.asAFError?.underlyingError?.localizedDescription.contains(postLimitReachedError) == true {
            return .postsLimitReached
        } else {
            return .zeroError(error)
        }
    }
    
    // MARK: - Crypto
    
    func ed25519Base64() async -> String? {
        await client.encryption().ed25519Key()
    }
    
    func curve25519Base64() async -> String? {
        await client.encryption().curve25519Key()
    }
    
    func pinUserIdentity(_ userID: String) async -> Result<Void, ClientProxyError> {
        MXLog.info("Pinning current identity for user: \(userID)")
        
        do {
            guard let userIdentity = try await client.encryption().userIdentity(userId: userID) else {
                MXLog.error("Failed retrieving identity for user: \(userID)")
                return .failure(.failedRetrievingUserIdentity)
            }
            
            return try await .success(userIdentity.pin())
        } catch {
            MXLog.error("Failed pinning current identity for user: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func withdrawUserIdentityVerification(_ userID: String) async -> Result<Void, ClientProxyError> {
        MXLog.info("Withdrawing current identity verification for user: \(userID)")
        
        do {
            guard let userIdentity = try await client.encryption().userIdentity(userId: userID) else {
                MXLog.error("Failed retrieving identity for user: \(userID)")
                return .failure(.failedRetrievingUserIdentity)
            }
            
            return try await .success(userIdentity.withdrawVerification())
        } catch {
            MXLog.error("Failed withdrawing current identity verification for user: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func resetIdentity() async -> Result<IdentityResetHandle?, ClientProxyError> {
        do {
            return try await .success(client.encryption().resetIdentity())
        } catch {
            return .failure(.sdkError(error))
        }
    }
    
    func userIdentity(for userID: String) async -> Result<UserIdentityProxyProtocol?, ClientProxyError> {
        do {
            return try await .success(client.encryption().userIdentity(userId: userID).map(UserIdentityProxy.init))
        } catch {
            MXLog.error("Failed retrieving user identity: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func verifyUserPassword(_ password: String) async -> Result<Void, ClientProxyError> {
        do {
            let verifyPasswordResult = try await zeroApiProxy.userAccountApi.verifyPassword(password: password)
            switch verifyPasswordResult {
            case .success:
                return .success(())
            case .failure(let error):
                MXLog.error("Failed to verify password: \(error)")
                return .failure(.zeroError(error))
            }
        } catch {
            MXLog.error("Failed to verify password: \(error)")
            return .failure(.zeroError(error))
        }
    }
    
    private func joinRoomExplicitly(_ roomId: String) async {
        do {
            _ = try await client.joinRoomById(roomId: roomId)
        } catch {
            MXLog.error("Failed to join invited room: \(roomId) with error: \(error)")
        }
    }
    
    private func fetchZeroCurrentUser() async throws -> ZCurrentUser? {
        let currentUser = try await zeroApiProxy.matrixUsersService.fetchCurrentUser()
        if currentUser != nil {
            zeroCurrentUserSubject.send(currentUser!)
        }
        return currentUser
    }
    
    func setRoomNotificationModeProtocol(_ listener: any RoomNotificationModeUpdatedProtocol) {
        roomNotificationModeUpdateProtocol = listener
    }
    
    func roomNotificationModeUpdated(roomId: String, notificationMode: RoomNotificationModeProxy) {
        roomNotificationModeUpdateProtocol?.onRoomNotificationModeUpdated(for: roomId, mode: notificationMode)
    }
}

extension ClientProxy: MediaLoaderProtocol {
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await mediaLoader.loadMediaContentForSource(source)
    }

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await mediaLoader.loadMediaThumbnailForSource(source, width: width, height: height)
    }
    
    func loadMediaFileForSource(_ source: MediaSourceProxy, filename: String?) async throws -> MediaFileHandleProxy {
        try await mediaLoader.loadMediaFileForSource(source, filename: filename)
    }
}

private class ClientDelegateWrapper: ClientDelegate {
    private let authErrorCallback: (Bool) -> Void
    
    init(authErrorCallback: @escaping (Bool) -> Void) {
        self.authErrorCallback = authErrorCallback
    }
    
    // MARK: - ClientDelegate

    func didReceiveAuthError(isSoftLogout: Bool) {
        MXLog.error("Received authentication error, softlogout=\(isSoftLogout)")
        authErrorCallback(isSoftLogout)
    }
    
    func didRefreshTokens() {
        MXLog.info("Delegating session updates to the ClientSessionDelegate.")
    }
}

private class ClientDecryptionErrorDelegate: UnableToDecryptDelegate {
    private let actionsSubject: PassthroughSubject<ClientProxyAction, Never>
    
    init(actionsSubject: PassthroughSubject<ClientProxyAction, Never>) {
        self.actionsSubject = actionsSubject
    }
    
    func onUtd(info: UnableToDecryptInfo) {
        actionsSubject.send(.receivedDecryptionError(info))
    }
}

private class IgnoredUsersListenerProxy: IgnoredUsersListener {
    private let onUpdateClosure: ([String]) -> Void

    init(onUpdateClosure: @escaping ([String]) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func call(ignoredUserIds: [String]) {
        onUpdateClosure(ignoredUserIds)
    }
}

private class SendQueueRoomErrorListenerProxy: SendQueueRoomErrorListener {
    private let onErrorClosure: (String, ClientError) -> Void
    
    init(onErrorClosure: @escaping (String, ClientError) -> Void) {
        self.onErrorClosure = onErrorClosure
    }
    
    func onError(roomId: String, error: ClientError) {
        onErrorClosure(roomId, error)
    }
}

private struct ClientProxyServices {
    let syncService: SyncService
    let roomListService: RoomListService
    let roomSummaryProvider: RoomSummaryProviderProtocol
    let alternateRoomSummaryProvider: RoomSummaryProviderProtocol
    let staticRoomSummaryProvider: StaticRoomSummaryProviderProtocol
    
    init(client: ClientProtocol,
         actionsSubject: PassthroughSubject<ClientProxyAction, Never>,
         notificationSettings: NotificationSettingsProxyProtocol,
         appSettings: AppSettings,
         zeroApiProxy: ZeroApiProxyProtocol) async throws {
        let syncService = try await client
            .syncService()
            .withCrossProcessLock()
            .finish()
        
        let roomListService = syncService.roomListService()
        
        let roomMessageEventStringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(cacheKey: "roomList",
                                                                                                                           mentionBuilder: PlainMentionBuilder()), destination: .roomList)
        let eventStringBuilder = try RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: client.userId(), shouldDisambiguateDisplayNames: false),
                                                            messageEventStringBuilder: roomMessageEventStringBuilder,
                                                            shouldDisambiguateDisplayNames: false,
                                                            shouldPrefixSenderName: true)
        
        roomSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                  eventStringBuilder: eventStringBuilder,
                                                  name: "AllRooms",
                                                  shouldUpdateVisibleRange: true,
                                                  notificationSettings: notificationSettings,
                                                  appSettings: appSettings,
                                                  zeroUsersService: zeroApiProxy.matrixUsersService)
        try await roomSummaryProvider.setRoomList(roomListService.allRooms())
        
        alternateRoomSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                           eventStringBuilder: eventStringBuilder,
                                                           name: "AlternateAllRooms",
                                                           notificationSettings: notificationSettings,
                                                           appSettings: appSettings,
                                                           zeroUsersService: zeroApiProxy.matrixUsersService)
        try await alternateRoomSummaryProvider.setRoomList(roomListService.allRooms())
        
        staticRoomSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                        eventStringBuilder: eventStringBuilder,
                                                        name: "StaticAllRooms",
                                                        roomListPageSize: .max,
                                                        notificationSettings: notificationSettings,
                                                        appSettings: appSettings,
                                                        zeroUsersService: zeroApiProxy.matrixUsersService)
        try await staticRoomSummaryProvider.setRoomList(roomListService.allRooms())
        
        self.syncService = syncService
        self.roomListService = roomListService
    }
}

private extension MediaPreviewConfig {
    var mediaPreviewVisibility: TimelineMediaVisibility {
        switch mediaPreviews {
        case .on:
            .always
        case .private:
            .privateOnly
        case .off:
            .never
        }
    }
    
    var hideInviteAvatars: Bool {
        switch inviteAvatars {
        case .off:
            true
        case .on:
            false
        }
    }
}

private extension TimelineMediaVisibility {
    var rustValue: MediaPreviews {
        switch self {
        case .always:
            .on
        case .never:
            .off
        case .privateOnly:
            .private
        }
    }
}
