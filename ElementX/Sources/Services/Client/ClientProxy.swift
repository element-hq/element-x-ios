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
import CryptoKit
import Foundation
import OrderedCollections

import MatrixRustSDK

class ClientProxy: ClientProxyProtocol {
    private let client: ClientProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private let appSettings: AppSettings
    private let networkMonitor: NetworkMonitorProtocol
    
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
    
    private var delegateHandle: TaskHandle?
    
    // These following summary providers both operate on the same allRooms() list but
    // can apply their own filtering and pagination
    private(set) var roomSummaryProvider: RoomSummaryProviderProtocol?
    private(set) var alternateRoomSummaryProvider: RoomSummaryProviderProtocol?
    
    private(set) var inviteSummaryProvider: RoomSummaryProviderProtocol?
    
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
    
    init(client: ClientProtocol,
         backgroundTaskService: BackgroundTaskServiceProtocol,
         appSettings: AppSettings,
         networkMonitor: NetworkMonitorProtocol) async {
        self.client = client
        self.backgroundTaskService = backgroundTaskService
        self.appSettings = appSettings
        self.networkMonitor = networkMonitor
        
        clientQueue = .init(label: "ClientProxyQueue", attributes: .concurrent)
        
        mediaLoader = MediaLoader(client: client)
        
        notificationSettings = NotificationSettingsProxy(notificationSettings: client.getNotificationSettings(),
                                                         backgroundTaskService: backgroundTaskService)
        
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
    }
    
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
            MXLog.error("Failed retrieving device id with error: \(error)")
            return nil
        }
    }

    var homeserver: String {
        client.homeserver()
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
        
        Task {
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
    
    func accountURL(action: AccountManagementAction) -> URL? {
        try? client.accountUrl(action: action).flatMap(URL.init(string:))
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
        let result: Result<String, ClientProxyError> = await Task.dispatch(on: clientQueue) {
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
                let result = try self.client.createRoom(request: parameters)
                return .success(result)
            } catch {
                MXLog.error("Failed creating direct room for userID: \(userID) with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
        
        return await waitForRoomSummary(with: result, name: expectedRoomName)
    }
    
    func createRoom(name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?) async -> Result<String, ClientProxyError> {
        let result: Result<String, ClientProxyError> = await Task.dispatch(on: clientQueue) {
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
                let roomID = try self.client.createRoom(request: parameters)
                return .success(roomID)
            } catch {
                MXLog.error("Failed creating room with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
        
        return await waitForRoomSummary(with: result, name: name)
    }
    
    func joinRoom(_ roomID: String) async -> Result<Void, ClientProxyError> {
        do {
            let _ = try await client.joinRoomById(roomId: roomID)
            
            // Wait for the room to appear in the room lists to avoid issues downstream
            let _ = await waitForRoomSummary(with: .success(roomID), name: nil, timeout: 30)
            
            return .success(())
        } catch {
            MXLog.error("Failed joining roomID: \(roomID) with error: \(error)")
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
    
    /// Await the room to be available in the room summary list
    private func waitForRoomSummary(with result: Result<String, ClientProxyError>, name: String?, timeout: Int = 10) async -> Result<String, ClientProxyError> {
        guard case .success(let roomID) = result else { return result }
        let runner = ExpiringTaskRunner { [weak self] in
            guard let roomLists = self?.roomSummaryProvider?.roomListPublisher.values else {
                return
            }
            // for every list of summaries, we check if we have a room summary with matching ID and name (if present)
            for await roomList in roomLists {
                guard let summary = roomList.first(where: { $0.id == roomID }) else { continue }
                guard let name else { break }
                if summary.name == name {
                    break
                }
            }
        }
        
        // we want to ignore the timeout error, and return the .success case because the room was properly created/joined already, we are only waiting for it to appear
        try? await runner.run(timeout: .seconds(timeout))
        return result
    }
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol? {
        // Try fetching the room from the cold cache (if available) first
        var (roomListItem, room) = await roomTupleForIdentifier(identifier)
        
        if let roomListItem, let room {
            return await RoomProxy(roomListItem: roomListItem,
                                   room: room,
                                   backgroundTaskService: backgroundTaskService)
        }
        
        // Else wait for the visible rooms list to go into fully loaded
        
        guard let roomSummaryProvider else {
            MXLog.error("Rooms summary provider not setup yet")
            return nil
        }
        
        if !roomSummaryProvider.statePublisher.value.isLoaded {
            _ = await roomSummaryProvider.statePublisher.values.first(where: { $0.isLoaded })
        }
        
        (roomListItem, room) = await roomTupleForIdentifier(identifier)
        
        guard let roomListItem else {
            MXLog.error("Invalid roomListItem for identifier \(identifier)")
            return nil
        }
        
        guard let room else {
            MXLog.error("Invalid roomListItem fullRoom for identifier \(identifier)")
            return nil
        }
        
        return await RoomProxy(roomListItem: roomListItem,
                               room: room,
                               backgroundTaskService: backgroundTaskService)
    }
    
    func roomPreviewForIdentifier(_ identifier: String) async -> Result<RoomPreviewDetails, ClientProxyError> {
        do {
            let roomPreview = try await client.getRoomPreview(roomIdOrAlias: identifier)
            return .success(.init(roomPreview))
        } catch {
            MXLog.error("Failed retrieving preview for room: \(identifier) with error: \(error)")
            return .failure(.sdkError(error))
        }
    }

    func loadUserDisplayName() async -> Result<Void, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let displayName = try self.client.displayName()
                self.userDisplayNameSubject.send(displayName)
                return .success(())
            } catch {
                MXLog.error("Failed loading user display name with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
    }
    
    func setUserDisplayName(_ name: String) async -> Result<Void, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                try self.client.setDisplayName(name: name)
                Task {
                    await self.loadUserDisplayName()
                }
                return .success(())
            } catch {
                MXLog.error("Failed setting user display name with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
    }

    func loadUserAvatarURL() async -> Result<Void, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let urlString = try self.client.avatarUrl()
                self.loadCachedAvatarURLTask?.cancel()
                self.userAvatarURLSubject.send(urlString.flatMap(URL.init))
                return .success(())
            } catch {
                MXLog.error("Failed loading user avatar URL with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
    }
    
    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError> {
        await Task.dispatch(on: .global()) {
            guard case let .image(imageURL, _, _) = media, let mimeType = media.mimeType else {
                MXLog.error("Failed uploading, invalid media: \(media)")
                return .failure(.invalidMedia)
            }
            
            do {
                let data = try Data(contentsOf: imageURL)
                try self.client.uploadAvatar(mimeType: mimeType, data: data)
                Task {
                    await self.loadUserAvatarURL()
                }
                return .success(())
            } catch {
                MXLog.error("Failed setting user avatar with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
    }
    
    func removeUserAvatar() async -> Result<Void, ClientProxyError> {
        await Task.dispatch(on: .global()) {
            do {
                try self.client.removeAvatar()
                Task {
                    await self.loadUserAvatarURL()
                }
                return .success(())
            } catch {
                MXLog.error("Failed removing user avatar with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
    }

    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let sessionVerificationController = try self.client.getSessionVerificationController()
                return .success(SessionVerificationControllerProxy(sessionVerificationController: sessionVerificationController))
            } catch {
                MXLog.error("Failed retrieving session verification controller proxy with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
    }

    func logout() async -> URL? {
        await Task.dispatch(on: clientQueue) {
            do {
                return try self.client.logout().flatMap(URL.init(string:))
            } catch {
                MXLog.error("Failed logging out with error: \(error)")
                return nil
            }
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
        await Task.dispatch(on: clientQueue) {
            do {
                return try .success(.init(sdkResults: self.client.searchUsers(searchTerm: searchTerm, limit: UInt64(limit))))
            } catch {
                MXLog.error("Failed searching users with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
    }
    
    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                return try .success(.init(sdkUserProfile: self.client.getProfile(userId: userID)))
            } catch {
                MXLog.error("Failed retrieving profile for userID: \(userID) with error: \(error)")
                return .failure(.sdkError(error))
            }
        }
    }
    
    func roomDirectorySearchProxy() -> RoomDirectorySearchProxyProtocol {
        RoomDirectorySearchProxy(roomDirectorySearch: client.roomDirectorySearch())
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
            guard let room = await roomForIdentifier(roomID),
                  room.isDirect,
                  let members = await room.members() else {
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
                .withUnifiedInvitesInRoomList(withUnifiedInvites: appSettings.roomListInvitesEnabled)
                .finish()
            let roomListService = syncService.roomListService()
            
            let roomMessageEventStringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(cacheKey: "roomList",
                                                                                                                               mentionBuilder: PlainMentionBuilder()))
            let eventStringBuilder = RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID, shouldDisambiguateDisplayNames: false),
                                                            messageEventStringBuilder: roomMessageEventStringBuilder,
                                                            shouldDisambiguateDisplayNames: false)
            
            roomSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                      eventStringBuilder: eventStringBuilder,
                                                      name: "AllRooms",
                                                      shouldUpdateVisibleRange: true,
                                                      notificationSettings: notificationSettings)
            try await roomSummaryProvider?.setRoomList(roomListService.allRooms())
            
            alternateRoomSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                               eventStringBuilder: eventStringBuilder,
                                                               name: "MessageForwarding",
                                                               notificationSettings: notificationSettings)
            try await alternateRoomSummaryProvider?.setRoomList(roomListService.allRooms())
            
            inviteSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                        eventStringBuilder: eventStringBuilder,
                                                        name: "Invites",
                                                        notificationSettings: notificationSettings)
            try await inviteSummaryProvider?.setRoomList(roomListService.invites())
            
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
            MXLog.info("Received room list update: \(state)")
            guard let self,
                  state != .error,
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
    
    private let eventFilters: TimelineEventTypeFilter = {
        let stateEventFilters: [StateEventType] = [.roomAliases,
                                                   .roomCanonicalAlias,
                                                   .roomGuestAccess,
                                                   .roomHistoryVisibility,
                                                   .roomJoinRules,
                                                   .roomPinnedEvents,
                                                   .roomPowerLevels,
                                                   .roomServerAcl,
                                                   .roomTombstone,
                                                   .spaceChild,
                                                   .spaceParent,
                                                   .policyRuleRoom,
                                                   .policyRuleServer,
                                                   .policyRuleUser]
        
        return .exclude(eventTypes: stateEventFilters.map { FilterTimelineEventType.state(eventType: $0) })
    }()

    private func roomTupleForIdentifier(_ identifier: String) async -> (RoomListItem?, Room?) {
        do {
            let roomListItem = try roomListService?.room(roomId: identifier)
            if roomListItem?.isTimelineInitialized() == false {
                try await roomListItem?.initTimeline(eventTypeFilter: eventFilters)
            }
            let fullRoom = try await roomListItem?.fullRoom()
            
            return (roomListItem, fullRoom)
        } catch {
            MXLog.error("Failed retrieving/initialising room with identifier: \(identifier)")
            return (nil, nil)
        }
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
