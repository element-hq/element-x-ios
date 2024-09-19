//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        
    private var roomListService: RoomListService?
    // periphery: ignore - only for retain
    private var roomListStateUpdateTaskHandle: TaskHandle?
    // periphery: ignore - only for retain
    private var roomListStateLoadingStateUpdateTaskHandle: TaskHandle?

    private var syncService: SyncService?
    // periphery: ignore - only for retain
    private var syncServiceStateUpdateTaskHandle: TaskHandle?
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var ignoredUsersListenerTaskHandle: TaskHandle?
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var verificationStateListenerTaskHandle: TaskHandle?
    
    // periphery:ignore - required for instance retention in the rust codebase
    private var sendQueueListenerTaskHandle: TaskHandle?
    
    private var delegateHandle: TaskHandle?
    
    // These following summary providers both operate on the same allRooms() list but
    // can apply their own filtering and pagination
    private(set) var roomSummaryProvider: RoomSummaryProviderProtocol?
    private(set) var alternateRoomSummaryProvider: RoomSummaryProviderProtocol?
    
    let notificationSettings: NotificationSettingsProxyProtocol

    let secureBackupController: SecureBackupControllerProtocol
    
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
    
    var roomsToAwait: Set<String> = []
    
    private let sendQueueStatusSubject = CurrentValueSubject<Bool, Never>(false)
    
    init(client: ClientProtocol,
         networkMonitor: NetworkMonitorProtocol,
         appSettings: AppSettings) async {
        self.client = client
        self.networkMonitor = networkMonitor
        self.appSettings = appSettings
        
        clientQueue = .init(label: "ClientProxyQueue", attributes: .concurrent)
        
        mediaLoader = MediaLoader(client: client)
        
        notificationSettings = NotificationSettingsProxy(notificationSettings: client.getNotificationSettings())
        
        secureBackupController = SecureBackupController(encryption: client.encryption())

        delegateHandle = client.setDelegate(delegate: ClientDelegateWrapper { [weak self] isSoftLogout in
            self?.hasEncounteredAuthError = true
            self?.actionsSubject.send(.receivedAuthError(isSoftLogout: isSoftLogout))
        })
        
        networkMonitor.reachabilityPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reachability in
                if reachability == .reachable {
                    self?.startSync()
                }
            }
            .store(in: &cancellables)
        
        await configureAppService()

        loadUserAvatarURLFromCache()
        
        ignoredUsersListenerTaskHandle = client.subscribeToIgnoredUsers(listener: IgnoredUsersListenerProxy { [weak self] ignoredUsers in
            self?.ignoredUsersSubject.send(ignoredUsers)
        })
        
        updateVerificationState(client.encryption().verificationState())
        
        verificationStateListenerTaskHandle = client.encryption().verificationStateListener(listener: VerificationStateListenerProxy { [weak self] verificationState in
            self?.updateVerificationState(verificationState)
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
    
    var slidingSyncVersion: SlidingSyncVersion {
        client.slidingSyncVersion()
    }
    
    var availableSlidingSyncVersions: [SlidingSyncVersion] {
        get async {
            await client.availableSlidingSyncVersions()
        }
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
            await syncService?.start()
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
    
    private func stopSync(completion: (() -> Void)?) {
        MXLog.info("Stopping sync")
        
        if restartTask != nil {
            MXLog.warning("Removing the sync service restart task.")
            restartTask = nil
        }
        
        // Capture the sync service strongly as this method is called on deinit and so the
        // existence of self when the Task executes is questionable and would sometimes crash.
        Task { [syncService] in
            do {
                defer {
                    completion?()
                }
                
                try await syncService?.stop()
            } catch {
                MXLog.error("Failed stopping the sync service with error: \(error)")
            }
        }
    }
    
    func accountURL(action: AccountManagementAction) async -> URL? {
        try? await client.accountUrl(action: action).flatMap(URL.init(string:))
    }
    
    func createDirectRoomIfNeeded(with userID: String, expectedRoomName: String?) async -> Result<(roomID: String, isNewRoom: Bool), ClientProxyError> {
        let currentDirectRoom = await directRoomForUserID(userID)
        switch currentDirectRoom {
        case .success(.some(let roomID)):
            return .success((roomID: roomID, isNewRoom: false))
        case .success(.none):
            switch await createDirectRoom(with: userID, expectedRoomName: expectedRoomName) {
            case .success(let roomID):
                return .success((roomID: roomID, isNewRoom: true))
            case .failure(let error):
                return .failure(.sdkError(error))
            }
        case .failure(let error):
            return .failure(.sdkError(error))
        }
    }
    
    func directRoomForUserID(_ userID: String) async -> Result<String?, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let roomID = try self.client.getDmRoom(userId: userID)?.id()
                return .success(roomID)
            } catch {
                MXLog.error("Failed retrieving direct room for userID: \(userID) with error: \(error)")
                return .failure(.sdkError(error))
            }
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
    
    func createRoom(name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?) async -> Result<String, ClientProxyError> {
        do {
            let parameters = CreateRoomParameters(name: name,
                                                  topic: topic,
                                                  isEncrypted: isRoomPrivate,
                                                  isDirect: false,
                                                  visibility: isRoomPrivate ? .private : .public,
                                                  preset: isRoomPrivate ? .privateChat : .publicChat,
                                                  invite: userIDs,
                                                  avatar: avatarURL?.absoluteString,
                                                  powerLevelContentOverride: Self.roomCreationPowerLevelOverrides)
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
        } catch {
            MXLog.error("Failed joining roomAlias: \(roomAlias) with error: \(error)")
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
        } catch let error as ClientError {
            MXLog.error("Failed uploading media with error: \(error)")
            return .failure(ClientProxyError.failedUploadingMedia(error, error.code))
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
        
        // Else wait for the visible rooms list to go into fully loaded
        guard let roomSummaryProvider else {
            MXLog.error("Rooms summary provider not setup yet")
            return nil
        }
        
        if !roomSummaryProvider.statePublisher.value.isLoaded {
            _ = await roomSummaryProvider.statePublisher.values.first(where: { $0.isLoaded })
        }
        
        if shouldAwait {
            await waitForRoomToSync(roomID: identifier)
        }
        
        return await buildRoomForIdentifier(identifier)
    }
    
    func roomPreviewForIdentifier(_ identifier: String, via: [String]) async -> Result<RoomPreviewDetails, ClientProxyError> {
        do {
            let roomPreview = try await client.getRoomPreviewFromRoomId(roomId: identifier, viaServers: via)
            return .success(.init(roomPreview))
        } catch let error as ClientError where error.code == .forbidden {
            return .failure(.roomPreviewIsPrivate)
        } catch {
            MXLog.error("Failed retrieving preview for room: \(identifier) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }

    func loadUserDisplayName() async -> Result<Void, ClientProxyError> {
        do {
            let displayName = try await client.displayName()
            userDisplayNameSubject.send(displayName)
            return .success(())
        } catch {
            MXLog.error("Failed loading user display name with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func setUserDisplayName(_ name: String) async -> Result<Void, ClientProxyError> {
        do {
            try await client.setDisplayName(name: name)
            Task {
                await self.loadUserDisplayName()
            }
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

    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        do {
            let sessionVerificationController = try await client.getSessionVerificationController()
            return .success(SessionVerificationControllerProxy(sessionVerificationController: sessionVerificationController))
        } catch {
            MXLog.error("Failed retrieving session verification controller proxy with error: \(error)")
            return .failure(.sdkError(error))
        }
    }

    func logout() async -> URL? {
        do {
            return try await client.logout().flatMap(URL.init(string:))
        } catch {
            MXLog.error("Failed logging out with error: \(error)")
            return nil
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
            return try await .success(.init(sdkResults: client.searchUsers(searchTerm: searchTerm, limit: UInt64(limit))))
        } catch {
            MXLog.error("Failed searching users with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError> {
        do {
            return try await .success(.init(sdkUserProfile: client.getProfile(userId: userID)))
        } catch {
            MXLog.error("Failed retrieving profile for userID: \(userID) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
    
    func roomDirectorySearchProxy() -> RoomDirectorySearchProxyProtocol {
        RoomDirectorySearchProxy(roomDirectorySearch: client.roomDirectorySearch())
    }
    
    func resolveRoomAlias(_ alias: String) async -> Result<ResolvedRoomAlias, ClientProxyError> {
        do {
            let resolvedAlias = try await client.resolveRoomAlias(roomAlias: alias)
            
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
    
    func getElementWellKnown() async -> Result<ElementWellKnown?, ClientProxyError> {
        await client.getElementWellKnown().map(ElementWellKnown.init)
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
                  roomProxy.isDirect,
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
    
    // MARK: - Private
    
    private func updateVerificationState(_ verificationState: VerificationState) {
        let verificationState: SessionVerificationState = switch verificationState {
        case .unknown:
            .unknown
        case .unverified:
            .unverified
        case .verified:
            .verified
        }
        
        verificationStateSubject.send(verificationState)
    }

    private func loadUserAvatarURLFromCache() {
        loadCachedAvatarURLTask = Task {
            let urlString = await Task.dispatch(on: clientQueue) {
                do {
                    return try self.client.cachedAvatarUrl()
                } catch {
                    MXLog.error("Failed to look for the avatar url in the cache: \(error)")
                    return nil
                }
            }
            guard !Task.isCancelled else { return }
            self.userAvatarURLSubject.value = urlString.flatMap(URL.init)
        }
    }

    private func configureAppService() async {
        guard syncService == nil else {
            fatalError("This shouldn't be called more than once")
        }
        
        do {
            let syncService = try await client
                .syncService()
                .withCrossProcessLock(appIdentifier: "MainApp")
                .withUtdHook(delegate: ClientDecryptionErrorDelegate(actionsSubject: actionsSubject))
                .finish()
            let roomListService = syncService.roomListService()
            
            let roomMessageEventStringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(cacheKey: "roomList",
                                                                                                                               mentionBuilder: PlainMentionBuilder()), prefix: .senderName)
            let eventStringBuilder = RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID, shouldDisambiguateDisplayNames: false),
                                                            messageEventStringBuilder: roomMessageEventStringBuilder,
                                                            shouldDisambiguateDisplayNames: false,
                                                            shouldPrefixSenderName: true)
            
            roomSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                      eventStringBuilder: eventStringBuilder,
                                                      name: "AllRooms",
                                                      shouldUpdateVisibleRange: true,
                                                      notificationSettings: notificationSettings,
                                                      appSettings: appSettings)
            try await roomSummaryProvider?.setRoomList(roomListService.allRooms())
            
            alternateRoomSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                               eventStringBuilder: eventStringBuilder,
                                                               name: "MessageForwarding",
                                                               notificationSettings: notificationSettings,
                                                               appSettings: appSettings)
            try await alternateRoomSummaryProvider?.setRoomList(roomListService.allRooms())
                        
            self.syncService = syncService
            self.roomListService = roomListService

            syncServiceStateUpdateTaskHandle = createSyncServiceStateObserver(syncService)
            roomListStateUpdateTaskHandle = createRoomListServiceObserver(roomListService)
            roomListStateLoadingStateUpdateTaskHandle = createRoomListLoadingStateUpdateObserver(roomListService)

        } catch {
            MXLog.error("Failed building room list service with error: \(error)")
        }
    }

    private func createSyncServiceStateObserver(_ syncService: SyncService) -> TaskHandle {
        syncService.state(listener: SyncServiceStateObserverProxy { [weak self] state in
            guard let self else { return }
            
            MXLog.info("Received sync service update: \(state)")
            
            switch state {
            case .running, .terminated, .idle:
                break
            case .error:
                restartSync()
            }
        })
    }

    private func createRoomListServiceObserver(_ roomListService: RoomListService) -> TaskHandle {
        roomListService.state(listener: RoomListStateListenerProxy { [weak self] state in
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
        roomListService.syncIndicator(delayBeforeShowingInMs: 1000, delayBeforeHidingInMs: 0, listener: RoomListServiceSyncIndicatorListenerProxy { [weak self] state in
            guard let self else { return }
            
            switch state {
            case .show:
                loadingStateSubject.send(.loading)
            case .hide:
                loadingStateSubject.send(.notLoading)
            }
        })
    }
    
    private lazy var eventFilters: TimelineEventTypeFilter = {
        var stateEventFilters: [StateEventType] = [.roomAliases,
                                                   .roomCanonicalAlias,
                                                   .roomGuestAccess,
                                                   .roomHistoryVisibility,
                                                   .roomJoinRules,
                                                   .roomPowerLevels,
                                                   .roomServerAcl,
                                                   .roomTombstone,
                                                   .spaceChild,
                                                   .spaceParent,
                                                   .policyRuleRoom,
                                                   .policyRuleServer,
                                                   .policyRuleUser]
        
        // Reminder: once the feature flag is not required anymore, change the lazy var back to a let
        if !appSettings.pinningEnabled {
            stateEventFilters.append(.roomPinnedEvents)
        }
        
        return .exclude(eventTypes: stateEventFilters.map { FilterTimelineEventType.state(eventType: $0) })
    }()
    
    private func buildRoomForIdentifier(_ roomID: String) async -> RoomProxyType? {
        guard let roomListService else {
            MXLog.error("Failed retrieving room: \(roomID), room list service not set up")
            return nil
        }
                
        do {
            let roomListItem = try roomListService.room(roomId: roomID)
            
            switch roomListItem.membership() {
            case .invited:
                return try .invited(InvitedRoomProxy(roomListItem: roomListItem,
                                                     room: roomListItem.invitedRoom()))
            case .joined:
                if roomListItem.isTimelineInitialized() == false {
                    try await roomListItem.initTimeline(eventTypeFilter: eventFilters, internalIdPrefix: nil)
                }
                
                let roomProxy = try await JoinedRoomProxy(roomListService: roomListService,
                                                          roomListItem: roomListItem,
                                                          room: roomListItem.fullRoom())
                
                return .joined(roomProxy)
            case .left:
                return .left
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
    
    // MARK: - Crypto
    
    func ed25519Base64() async -> String? {
        await client.encryption().ed25519Key()
    }
    
    func curve25519Base64() async -> String? {
        await client.encryption().curve25519Key()
    }
    
    func resetIdentity() async -> Result<IdentityResetHandle?, ClientProxyError> {
        do {
            return try await .success(client.encryption().resetIdentity())
        } catch {
            return .failure(.sdkError(error))
        }
    }
}

extension ClientProxy: MediaLoaderProtocol {
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await mediaLoader.loadMediaContentForSource(source)
    }

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await mediaLoader.loadMediaThumbnailForSource(source, width: width, height: height)
    }
    
    func loadMediaFileForSource(_ source: MediaSourceProxy, body: String?) async throws -> MediaFileHandleProxy {
        try await mediaLoader.loadMediaFileForSource(source, body: body)
    }
}

private class SyncServiceStateObserverProxy: SyncServiceStateObserver {
    private let onUpdateClosure: (SyncServiceState) -> Void

    init(onUpdateClosure: @escaping (SyncServiceState) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }

    func onUpdate(state: SyncServiceState) {
        onUpdateClosure(state)
    }
}

private class RoomListStateListenerProxy: RoomListServiceStateListener {
    private let onUpdateClosure: (RoomListServiceState) -> Void

    init(onUpdateClosure: @escaping (RoomListServiceState) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }

    func onUpdate(state: RoomListServiceState) {
        onUpdateClosure(state)
    }
}

private class RoomListServiceSyncIndicatorListenerProxy: RoomListServiceSyncIndicatorListener {
    private let onUpdateClosure: (RoomListServiceSyncIndicator) -> Void

    init(onUpdateClosure: @escaping (RoomListServiceSyncIndicator) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(syncIndicator: RoomListServiceSyncIndicator) {
        onUpdateClosure(syncIndicator)
    }
}

private class VerificationStateListenerProxy: VerificationStateListener {
    private let onUpdateClosure: (VerificationState) -> Void

    init(onUpdateClosure: @escaping (VerificationState) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(status: VerificationState) {
        onUpdateClosure(status)
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

private extension RoomPreviewDetails {
    init(_ roomPreview: RoomPreview) {
        self = RoomPreviewDetails(roomID: roomPreview.roomId,
                                  name: roomPreview.name,
                                  canonicalAlias: roomPreview.canonicalAlias,
                                  topic: roomPreview.topic,
                                  avatarURL: roomPreview.avatarUrl.flatMap(URL.init(string:)),
                                  memberCount: UInt(roomPreview.numJoinedMembers),
                                  isHistoryWorldReadable: roomPreview.isHistoryWorldReadable,
                                  isJoined: roomPreview.isJoined,
                                  isInvited: roomPreview.isInvited,
                                  isPublic: roomPreview.isPublic,
                                  canKnock: roomPreview.canKnock)
    }
}
