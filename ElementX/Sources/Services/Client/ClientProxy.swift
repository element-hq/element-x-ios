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
import UIKit

class ClientProxy: ClientProxyProtocol {
    private let client: ClientProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private var sessionVerificationControllerProxy: SessionVerificationControllerProxy?
    private let mediaLoader: MediaLoaderProtocol
    private let clientQueue: DispatchQueue
        
    private var roomListService: RoomListService?
    private var roomListStateUpdateTaskHandle: TaskHandle?

    private var encryptionSyncService: EncryptionSync?
    private var isEncryptionSyncing = false

    var roomSummaryProvider: RoomSummaryProviderProtocol?
    var inviteSummaryProvider: RoomSummaryProviderProtocol?

    private let roomListRecencyOrderingAllowedEventTypes = ["m.room.message", "m.room.encrypted", "m.sticker"]

    private var loadCachedAvatarURLTask: Task<Void, Never>?
    private let avatarURLSubject = CurrentValueSubject<URL?, Never>(nil)
    var avatarURLPublisher: AnyPublisher<URL?, Never> {
        avatarURLSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    private var visibleRoomsListProxyStateObservationToken: AnyCancellable?
    
    deinit {
        client.setDelegate(delegate: nil)
        stopSync()
    }
    
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    init(client: ClientProtocol, backgroundTaskService: BackgroundTaskServiceProtocol) async {
        self.client = client
        self.backgroundTaskService = backgroundTaskService
        clientQueue = .init(label: "ClientProxyQueue", attributes: .concurrent)
        
        mediaLoader = MediaLoader(client: client, clientQueue: clientQueue)

        client.setDelegate(delegate: ClientDelegateWrapper { [weak self] isSoftLogout in
            self?.callbacks.send(.receivedAuthError(isSoftLogout: isSoftLogout))
        } tokenRefreshCallback: { [weak self] in
            self?.callbacks.send(.updateRestorationToken)
        })
        
        await configureRoomListService()

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

    var deviceId: String? {
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

    var restorationToken: RestorationToken? {
        do {
            return try RestorationToken(session: client.session())
        } catch {
            MXLog.error("Failed retrieving restore token with error: \(error)")
            return nil
        }
    }

    var isSyncing: Bool {
        let isRoomListServiceSyncing = roomListService?.isSyncing() ?? false
        
        if ServiceLocator.shared.settings.isEncryptionSyncEnabled {
            return isRoomListServiceSyncing && isEncryptionSyncing
        } else {
            return isRoomListServiceSyncing
        }
    }
    
    func startSync() {
        MXLog.info("Starting sync")
        guard !isSyncing else {
            return
        }

        startEncryptionSyncService()
        roomListService?.sync()
    }
    
    func stopSync() {
        MXLog.info("Stopping sync")
        stopEncryptionSyncService()

        do {
            try roomListService?.stopSync()
        } catch {
            MXLog.error("Failed stopping room list service with error: \(error)")
        }
    }

    private func stopEncryptionSyncService() {
        guard isEncryptionSyncing else {
            return
        }
        isEncryptionSyncing = false
        encryptionSyncService?.stop()
        MXLog.info("Stopping Encryption Sync service")
    }
    
    func directRoomForUserID(_ userID: String) async -> Result<String?, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let roomId = try self.client.getDmRoom(userId: userID)?.id()
                return .success(roomId)
            } catch {
                return .failure(.failedRetrievingDirectRoom)
            }
        }
    }
    
    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError> {
        let result: Result<String, ClientProxyError> = await Task.dispatch(on: clientQueue) {
            do {
                let parameters = CreateRoomParameters(name: nil, topic: nil, isEncrypted: true, isDirect: true, visibility: .private, preset: .trustedPrivateChat, invite: [userID], avatar: nil)
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
                                                      avatar: avatarURL?.absoluteString)
                let roomId = try self.client.createRoom(request: parameters)
                return .success(roomId)
            } catch {
                return .failure(.failedCreatingRoom)
            }
        }
        
        return await waitForRoomSummary(with: result, name: name)
    }
    
    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError> {
        guard let mimeType = media.mimeType else { return .failure(ClientProxyError.mediaFileError) }
        return await Task.dispatch(on: clientQueue) {
            do {
                let data = try Data(contentsOf: media.url)
                let matrixUrl = try self.client.uploadMedia(mimeType: mimeType, data: [UInt8](data), progressWatcher: nil)
                return .success(matrixUrl)
            } catch let error as ClientError {
                return .failure(ClientProxyError.failedUploadingMedia(error.code))
            } catch {
                return .failure(ClientProxyError.mediaFileError)
            }
        }
    }
    
    /// Await the room to be available in the room summary list
    /// - Parameter result: the result of a room creation Task with the roomId
    private func waitForRoomSummary(with result: Result<String, ClientProxyError>, name: String?) async -> Result<String, ClientProxyError> {
        guard case .success(let roomId) = result else { return result }
        let runner = ExpiringTaskRunner { [weak self] in
            guard let roomLists = self?.roomSummaryProvider?.roomListPublisher.values else {
                return
            }
            // for every list of summaries, we check if we have a room summary with matching ID and name (if present)
            for await roomList in roomLists {
                guard let summary = roomList.first(where: { $0.id == roomId }) else { continue }
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
        var (roomListItem, room) = await Task.dispatch(on: clientQueue) {
            self.roomTupleForIdentifier(identifier)
        }
        
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
        
        (roomListItem, room) = await Task.dispatch(on: clientQueue) {
            self.roomTupleForIdentifier(identifier)
        }
        
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

    func loadUserDisplayName() async -> Result<String, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let displayName = try self.client.displayName()
                return .success(displayName)
            } catch {
                return .failure(.failedRetrievingDisplayName)
            }
        }
    }

    func loadUserAvatarURL() async {
        await Task.dispatch(on: clientQueue) {
            do {
                let urlString = try self.client.avatarUrl()
                self.loadCachedAvatarURLTask?.cancel()
                self.avatarURLSubject.value = urlString.flatMap(URL.init)
            } catch {
                MXLog.error("Failed fetching the user avatar url: \(error)")
                return
            }
        }
    }

    func accountDataEvent<Content>(type: String) async -> Result<Content?, ClientProxyError> where Content: Decodable {
        await Task.dispatch(on: clientQueue) {
            .failure(.failedRetrievingAccountData)
        }
    }
    
    func setAccountData<Content: Encodable>(content: Content, type: String) async -> Result<Void, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            .failure(.failedSettingAccountData)
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

    func logout() async {
        await Task.dispatch(on: clientQueue) {
            do {
                try self.client.logout()
            } catch {
                MXLog.error("Failed logging out with error: \(error)")
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
    
    private func restartSync() {
        stopSync()
        startSync()
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
            self.avatarURLSubject.value = urlString.flatMap(URL.init)
        }
    }

    private func startEncryptionSyncService() {
        guard ServiceLocator.shared.settings.isEncryptionSyncEnabled else {
            return
        }
        configureEncryptionSyncService()
    }
    
    private func configureEncryptionSyncService() {
        do {
            let listener = EncryptionSyncListenerProxy { [weak self] reason in
                switch reason {
                case .done:
                    MXLog.info("Encryption Sync has finished for user: \(self?.userID ?? "unknown")")
                case .error(let msg):
                    MXLog.error("Encryption Sync has terminated for user: \(self?.userID ?? "unknown") for reason: \(msg)")
                    guard let self else {
                        return
                    }
                    Task {
                        self.configureEncryptionSyncService()
                    }
                }
            }
            let encryptionSync = try client.mainEncryptionSync(id: "Main App", listener: listener)
            encryptionSync.reloadCaches()
            isEncryptionSyncing = true
            encryptionSyncService = encryptionSync
            MXLog.info("Encryption sync started for user: \(userID)")
        } catch {
            MXLog.error("Configure encryption sync failed with error: \(error)")
        }
    }

    private func configureRoomListService() async {
        guard roomListService == nil else {
            fatalError("This shouldn't be called more than once")
        }
        
        do {
            let roomListService = try ServiceLocator.shared.settings.isEncryptionSyncEnabled ? client.roomListService() : client.roomListServiceWithEncryption()
            roomListStateUpdateTaskHandle = roomListService.state(listener: RoomListStateListenerProxy { [weak self] state in
                guard let self else { return }
                MXLog.info("Received room list update: \(state)")
                
                // Restart the room list sync on every error for now
                if state == .error {
                    self.restartSync()
                }
                
                // The invites are available only when entering `running`
                if state == .running {
                    Task {
                        do {
                            // Subscribe to invites later as the underlying SlidingSync list is only added when entering AllRooms
                            try await self.inviteSummaryProvider?.setRoomList(roomListService.invites())
                        } catch {
                            MXLog.error("Failed configuring invites room list with error: \(error)")
                        }
                    }
                }
                
                // Anything that's not `running` is interpreted as "Loading data"
                if state == .running {
                    self.callbacks.send(.receivedSyncUpdate)
                } else {
                    self.callbacks.send(.startedUpdating)
                }
            })
            
            roomSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                      eventStringBuilder: RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID)),
                                                      name: "AllRooms")
            
            try await roomSummaryProvider?.setRoomList(roomListService.allRooms())
            
            inviteSummaryProvider = RoomSummaryProvider(roomListService: roomListService,
                                                        eventStringBuilder: RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID)),
                                                        name: "Invites")
            
            self.roomListService = roomListService
        } catch {
            MXLog.error("Failed building room list service with error: \(error)")
        }
    }
    
    private func roomTupleForIdentifier(_ identifier: String) -> (RoomListItem?, Room?) {
        do {
            let roomListItem = try roomListService?.room(roomId: identifier)
            let fullRoom = roomListItem?.fullRoom()
            
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

private class RoomListStateListenerProxy: RoomListServiceStateListener {
    private let onUpdateClosure: (RoomListServiceState) -> Void
   
    init(_ onUpdateClosure: @escaping (RoomListServiceState) -> Void) {
        self.onUpdateClosure = onUpdateClosure
    }
    
    func onUpdate(state: RoomListServiceState) {
        onUpdateClosure(state)
    }
}

private class ClientDelegateWrapper: ClientDelegate {
    private let authErrorCallback: (Bool) -> Void
    private let tokenRefreshCallback: () -> Void
    
    init(authErrorCallback: @escaping (Bool) -> Void,
         tokenRefreshCallback: @escaping () -> Void) {
        self.authErrorCallback = authErrorCallback
        self.tokenRefreshCallback = tokenRefreshCallback
    }
    
    // MARK: - ClientDelegate

    func didReceiveAuthError(isSoftLogout: Bool) {
        MXLog.error("Received authentication error, softlogout=\(isSoftLogout)")
        authErrorCallback(isSoftLogout)
    }
    
    func didRefreshTokens() {
        MXLog.info("The session has updated tokens.")
        tokenRefreshCallback()
    }
}
