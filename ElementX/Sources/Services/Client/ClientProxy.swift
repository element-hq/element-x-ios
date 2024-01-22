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
import MatrixRustSDK
import SwiftUI

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
    
    private var delegateHandle: TaskHandle?
    
    // These following summary providers both operate on the same allRooms() list but
    // can apply their own filtering and pagination
    private(set) var roomSummaryProvider: RoomSummaryProviderProtocol?
    private(set) var messageForwardingRoomSummaryProvider: RoomSummaryProviderProtocol?
    
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
    var userAvatarURL: CurrentValuePublisher<URL?, Never> {
        userAvatarURLSubject.asCurrentValuePublisher()
    }
    
    private let userDisplayNameSubject = CurrentValueSubject<String?, Never>(nil)
    var userDisplayName: CurrentValuePublisher<String?, Never> {
        userDisplayNameSubject.asCurrentValuePublisher()
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
    
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    private let loadingStateSubject = CurrentValueSubject<ClientProxyLoadingState, Never>(.notLoading)
    var loadingStatePublisher: CurrentValuePublisher<ClientProxyLoadingState, Never> {
        loadingStateSubject.asCurrentValuePublisher()
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
        
        mediaLoader = MediaLoader(client: client, clientQueue: clientQueue)
        
        notificationSettings = NotificationSettingsProxy(notificationSettings: client.getNotificationSettings(),
                                                         backgroundTaskService: backgroundTaskService)
        
        secureBackupController = SecureBackupController(encryption: client.encryption())

        delegateHandle = client.setDelegate(delegate: ClientDelegateWrapper { [weak self] isSoftLogout in
            self?.hasEncounteredAuthError = true
            self?.callbacks.send(.receivedAuthError(isSoftLogout: isSoftLogout))
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

    var session: Session? {
        do {
            return try client.session()
        } catch {
            MXLog.error("Failed retrieving the client's session with error: \(error)")
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
    
    func stopSync() {
        stopSync(completion: nil)
    }
    
    private func stopSync(completion: (() -> Void)?) {
        MXLog.info("Stopping sync")
        
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
    
    func directRoomForUserID(_ userID: String) async -> Result<String?, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let roomID = try self.client.getDmRoom(userId: userID)?.id()
                return .success(roomID)
            } catch {
                return .failure(.failedRetrievingDirectRoom)
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
                return .failure(.failedCreatingRoom)
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
                return .failure(.failedCreatingRoom)
            }
        }
        
        return await waitForRoomSummary(with: result, name: name)
    }
    
    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError> {
        guard let mimeType = media.mimeType else { return .failure(ClientProxyError.mediaFileError) }
        do {
            let data = try Data(contentsOf: media.url)
            let matrixUrl = try await client.uploadMedia(mimeType: mimeType, data: data, progressWatcher: nil)
            return .success(matrixUrl)
        } catch let error as ClientError {
            return .failure(ClientProxyError.failedUploadingMedia(error.code))
        } catch {
            return .failure(ClientProxyError.mediaFileError)
        }
    }
    
    /// Await the room to be available in the room summary list
    /// - Parameter result: the result of a room creation Task with the `roomID`.
    private func waitForRoomSummary(with result: Result<String, ClientProxyError>, name: String?) async -> Result<String, ClientProxyError> {
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
        
        // we want to ignore the timeout error, and return the .success case because the room it was properly created already, we are only waiting for it to appear
        try? await runner.run(timeout: .seconds(10))
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

    func loadUserDisplayName() async -> Result<Void, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let displayName = try self.client.displayName()
                self.userDisplayNameSubject.send(displayName)
                return .success(())
            } catch {
                return .failure(.failedRetrievingUserDisplayName)
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
                return .failure(.failedSettingUserDisplayName)
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
                return .failure(.failedRetrievingUserAvatarURL)
            }
        }
    }
    
    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError> {
        await Task.dispatch(on: .global()) {
            guard case let .image(imageURL, _, _) = media, let mimeType = media.mimeType else {
                return .failure(.failedSettingUserAvatar)
            }
            
            do {
                let data = try Data(contentsOf: imageURL)
                try self.client.uploadAvatar(mimeType: mimeType, data: data)
                Task {
                    await self.loadUserAvatarURL()
                }
                return .success(())
            } catch {
                return .failure(.failedSettingUserAvatar)
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
                return .failure(.failedSettingUserAvatar)
            }
        }
    }

    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let sessionVerificationController = try self.client.getSessionVerificationController()
                return .success(SessionVerificationControllerProxy(sessionVerificationController: sessionVerificationController))
            } catch {
                return .failure(.failedRetrievingSessionVerificationController)
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
        try await Task.dispatch(on: .global()) {
            try self.client.setPusher(identifiers: configuration.identifiers,
                                      kind: configuration.kind,
                                      appDisplayName: configuration.appDisplayName,
                                      deviceDisplayName: configuration.deviceDisplayName,
                                      profileTag: configuration.profileTag,
                                      lang: configuration.lang)
        }
    }
    
    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                return try .success(.init(sdkResults: self.client.searchUsers(searchTerm: searchTerm, limit: UInt64(limit))))
            } catch {
                return .failure(.failedSearchingUsers)
            }
        }
    }
    
    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                return try .success(.init(sdkUserProfile: self.client.getProfile(userId: userID)))
            } catch {
                return .failure(.failedGettingUserProfile)
            }
        }
    }
    
    // MARK: Private

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
                .finish()
            let roomListService = syncService.roomListService()
            
            let roomMessageEventStringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(cacheKey: "roomList",
                                                                                                                               permalinkBaseURL: appSettings.permalinkBaseURL,
                                                                                                                               mentionBuilder: PlainMentionBuilder()))
            let eventStringBuilder = RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID),
                                                            messageEventStringBuilder: roomMessageEventStringBuilder)
            roomSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                      eventStringBuilder: eventStringBuilder,
                                                      name: "AllRooms",
                                                      shouldUpdateVisibleRange: true,
                                                      notificationSettings: notificationSettings,
                                                      backgroundTaskService: backgroundTaskService,
                                                      appSettings: appSettings)
            try await roomSummaryProvider?.setRoomList(roomListService.allRooms())
            
            messageForwardingRoomSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                                       eventStringBuilder: eventStringBuilder,
                                                                       name: "MessageForwarding",
                                                                       notificationSettings: notificationSettings,
                                                                       backgroundTaskService: backgroundTaskService,
                                                                       appSettings: appSettings)
            try await messageForwardingRoomSummaryProvider?.setRoomList(roomListService.allRooms())
            
            inviteSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                        eventStringBuilder: eventStringBuilder,
                                                        name: "Invites",
                                                        notificationSettings: notificationSettings,
                                                        backgroundTaskService: backgroundTaskService,
                                                        appSettings: appSettings)
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
                startSync()
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
            callbacks.send(.receivedSyncUpdate)
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
    
    private func roomTupleForIdentifier(_ identifier: String) async -> (RoomListItem?, Room?) {
        do {
            let roomListItem = try roomListService?.room(roomId: identifier)
            let fullRoom = await roomListItem?.fullRoom()
            
            return (roomListItem, fullRoom)
        } catch {
            MXLog.error("Failed retrieving room with identifier: \(identifier)")
            return (nil, nil)
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
