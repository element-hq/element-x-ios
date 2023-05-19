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

private class WeakClientProxyWrapper: ClientDelegate, NotificationDelegate, SlidingSyncObserver {
    private weak var clientProxy: ClientProxy?
    
    init(clientProxy: ClientProxy) {
        self.clientProxy = clientProxy
    }
    
    // MARK: - ClientDelegate

    func didReceiveAuthError(isSoftLogout: Bool) {
        MXLog.error("Received authentication error, softlogout=\(isSoftLogout)")
        clientProxy?.didReceiveAuthError(isSoftLogout: isSoftLogout)
    }
    
    func didRefreshTokens() {
        MXLog.info("The session has updated tokens.")
        clientProxy?.updateRestorationToken()
    }

    // MARK: - SlidingSyncDelegate
    
    func didReceiveSyncUpdate(summary: UpdateSummary) {
        MXLog.info("Received sliding sync update")
        clientProxy?.didReceiveSlidingSyncUpdate(summary: summary)
    }

    // MARK: - NotificationDelegate

    func didReceiveNotification(notification: MatrixRustSDK.NotificationItem) {
        guard let userID = clientProxy?.userID else { return }
        clientProxy?.didReceiveNotification(notification: NotificationItemProxy(notificationItem: notification, receiverID: userID))
    }
}

class ClientProxy: ClientProxyProtocol {
    private let client: ClientProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private var sessionVerificationControllerProxy: SessionVerificationControllerProxy?
    private let mediaLoader: MediaLoaderProtocol
    private let clientQueue: DispatchQueue
    
    private var slidingSyncObserverToken: TaskHandle?
    private var slidingSync: SlidingSyncProtocol?
    private var slidingSyncTasks = [TaskHandle?]()
    
    var visibleRoomsListBuilder: SlidingSyncListBuilder?
    var visibleRoomsListProxy: SlidingSyncListProxy?
    var visibleRoomsSummaryProvider: RoomSummaryProviderProtocol?
    
    var allRoomsListBuilder: SlidingSyncListBuilder?
    var allRoomsListProxy: SlidingSyncListProxy?
    var allRoomsSummaryProvider: RoomSummaryProviderProtocol?

    var invitesListBuilder: SlidingSyncListBuilder?
    var invitesListProxy: SlidingSyncListProxy?
    var invitesSummaryProvider: RoomSummaryProviderProtocol?

    var notificationsListBuilder: SlidingSyncListBuilder?

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
        // These need to be inlined instead of using stopSync()
        // as we can't call async methods safely from deinit
        client.setDelegate(delegate: nil)
        slidingSyncObserverToken?.cancel()
        slidingSync?.setObserver(observer: nil)
    }
    
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    init(client: ClientProtocol, backgroundTaskService: BackgroundTaskServiceProtocol) async {
        self.client = client
        self.backgroundTaskService = backgroundTaskService
        clientQueue = .init(label: "ClientProxyQueue", attributes: .concurrent)
        
        mediaLoader = MediaLoader(client: client, clientQueue: clientQueue)

        let delegate = WeakClientProxyWrapper(clientProxy: self)
        client.setDelegate(delegate: delegate)

        // Set up sync listener for generating local notifications.
        if ServiceLocator.shared.settings.enableLocalPushNotifications {
            await Task.dispatch(on: clientQueue) {
                client.setNotificationDelegate(notificationDelegate: delegate)
            }
        }
        
        configureSlidingSync()

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
        slidingSyncObserverToken != nil
    }
    
    func startSync() {
        MXLog.info("Starting sync")
        guard !isSyncing else {
            return
        }
        
        slidingSyncObserverToken = slidingSync?.sync()
    }

    func stopSync(completionHandler: () -> Void) {
        guard let slidingSyncObserverToken else {
            MXLog.info("No sync is present")
            return
        }
        stopSync()
        while !slidingSyncObserverToken.isFinished() { }
        completionHandler()
    }

    func stopSync() {
        MXLog.info("Stopping sync")
        slidingSyncObserverToken?.cancel()
        slidingSyncObserverToken = nil
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
    
    func createDirectRoom(with userProfile: UserProfile) async -> Result<String, ClientProxyError> {
        let result: Result<String, ClientProxyError> = await Task.dispatch(on: clientQueue) {
            do {
                let parameters = CreateRoomParameters(name: nil, topic: nil, isEncrypted: true, isDirect: true, visibility: .private, preset: .trustedPrivateChat, invite: [userProfile.userID], avatar: nil)
                let result = try self.client.createRoom(request: parameters)
                return .success(result)
            } catch {
                return .failure(.failedCreatingRoom)
            }
        }
        
        return await waitForRoomSummary(with: result, name: userProfile.displayName)
    }
    
    func createRoom(with parameters: CreateRoomFlowParameters, users: [UserProfile]) async -> Result<String, ClientProxyError> {
        let result: Result<String, ClientProxyError> = await Task.dispatch(on: clientQueue) {
            do {
                let parameters = CreateRoomParameters(name: parameters.name,
                                                      topic: parameters.topic,
                                                      isEncrypted: parameters.isRoomPrivate,
                                                      isDirect: false,
                                                      visibility: parameters.isRoomPrivate ? .private : .public,
                                                      preset: parameters.isRoomPrivate ? .privateChat : .publicChat,
                                                      invite: users.map(\.userID),
                                                      avatar: nil)
                let roomId = try self.client.createRoom(request: parameters)
                return .success(roomId)
            } catch {
                return .failure(.failedCreatingRoom)
            }
        }
        
        return await waitForRoomSummary(with: result, name: parameters.name)
    }
    
    /// Await the room to be available in the room summary list
    /// - Parameter result: the result of a room creation Task with the roomId
    private func waitForRoomSummary(with result: Result<String, ClientProxyError>, name: String?) async -> Result<String, ClientProxyError> {
        guard case .success(let roomId) = result else { return result }
        let runner = Runner { [weak self] in
            guard let roomLists = self?.visibleRoomsSummaryProvider?.roomListPublisher.values else {
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
        try? await runner.run(timeout: 10)
        return result
    }
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol? {
        let (slidingSyncRoom, room) = await Task.dispatch(on: clientQueue) {
            self.roomTupleForIdentifier(identifier)
        }

        guard let slidingSyncRoom else {
            MXLog.error("Invalid slidingSyncRoom for identifier \(identifier)")
            return nil
        }
        
        guard let room else {
            MXLog.error("Invalid slidingSyncRoom fullRoom for identifier \(identifier)")
            return nil
        }

        return await RoomProxy(slidingSyncRoom: slidingSyncRoom,
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
    
    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResults, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                return try .success(.init(sdkResults: self.client.searchUsers(searchTerm: searchTerm, limit: UInt64(limit))))
            } catch {
                return .failure(.failedSearchingUsers)
            }
        }
    }
    
    func profile(for userID: String) async -> Result<UserProfile, ClientProxyError> {
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
            self.avatarURLSubject.value = urlString.flatMap(URL.init)
        }
    }
        
    private func configureSlidingSync() {
        guard slidingSync == nil else {
            fatalError("This shouldn't be called more than once")
        }
        
        do {
            let slidingSyncBuilder = client.slidingSync()
            
            // List observers need to be setup before calling build() on the SlidingSyncBuilder otherwise
            // cold cache state and count updates will be lost
            buildAndConfigureVisibleRoomsSlidingSyncList()
            buildAndConfigureAllRoomsSlidingSyncList()
            buildAndConfigureInvitesSlidingSyncList()
            if ServiceLocator.shared.settings.enableLocalPushNotifications {
                buildAndConfigureNotificationsSlidingSyncList()
            }
            
            guard let visibleRoomsListBuilder else {
                MXLog.error("Visible rooms sliding sync view unavailable")
                return
            }
            
            let roomListRecencyOrderingAllowedEventTypes = ["m.room.message", "m.room.encrypted", "m.sticker"]
            
            // Add the visibleRoomsSlidingSyncList here so that it can take advantage of the SS builder cold cache
            // We will still register the allRoomsSlidingSyncList later, and than will have no cache
            let slidingSync = try slidingSyncBuilder
                .addList(listBuilder: visibleRoomsListBuilder)
                .withCommonExtensions()
                .bumpEventTypes(bumpEventTypes: roomListRecencyOrderingAllowedEventTypes)
                // .storageKey(name: "ElementX")
                .build()
            
            // Don't forget to update the view proxies after building the slidingSync
            visibleRoomsListProxy?.setSlidingSync(slidingSync: slidingSync)
            allRoomsListProxy?.setSlidingSync(slidingSync: slidingSync)
            invitesListProxy?.setSlidingSync(slidingSync: slidingSync)
            
            // Build the room summary providers later so the sliding sync view proxies are up to date and the
            // currentRoomList is populated with the data from the cold cache
            buildRoomSummaryProviders()
            
            slidingSync.setObserver(observer: WeakClientProxyWrapper(clientProxy: self))
            
            self.slidingSync = slidingSync
        } catch {
            MXLog.error("Failed building sliding sync with error: \(error)")
        }
    }
    
    private func buildAndConfigureVisibleRoomsSlidingSyncList() {
        guard visibleRoomsListBuilder == nil else {
            fatalError("This shouldn't be called more than once")
        }
        
        let listName = "CurrentlyVisibleRooms"
        
        let visibleRoomsListProxy = SlidingSyncListProxy(name: listName)
        
        let visibleRoomsListBuilder = SlidingSyncListBuilder(name: listName)
            .timelineLimit(limit: UInt32(SlidingSyncConstants.initialTimelineLimit)) // Starts off with zero to quickly load rooms, then goes to 1 while scrolling to quickly load last messages and 20 when the scrolling stops to load room history
            .requiredState(requiredState: slidingSyncRequiredState)
            .filters(filters: slidingSyncFilters)
            .syncMode(mode: .selective)
            .addRange(from: 0, toIncluded: 20)
            .onceBuilt(callback: visibleRoomsListProxy)

        self.visibleRoomsListBuilder = visibleRoomsListBuilder
        self.visibleRoomsListProxy = visibleRoomsListProxy

        // The allRoomsSlidingSyncList will be registered as soon as the visibleRoomsSlidingSyncList receives its first update
        visibleRoomsListProxyStateObservationToken = visibleRoomsListProxy.statePublisher.sink { [weak self] state in
            guard state == .fullyLoaded else {
                return
            }
            
            MXLog.info("Visible rooms view received first update, configuring views post initial sync")
            self?.configureViewsPostInitialSync()
            self?.visibleRoomsListProxyStateObservationToken = nil
        }
    }
    
    private func buildAndConfigureAllRoomsSlidingSyncList() {
        guard allRoomsListBuilder == nil else {
            fatalError("This shouldn't be called more than once")
        }
        
        let listName = "AllRooms"
        
        let allRoomsListProxy = SlidingSyncListProxy(name: listName)

        let allRoomsListBuilder = SlidingSyncListBuilder(name: listName)
            .noTimelineLimit()
            .requiredState(requiredState: slidingSyncRequiredState)
            .filters(filters: slidingSyncFilters)
            .syncMode(mode: .growing)
            .batchSize(batchSize: 100)
            .onceBuilt(callback: allRoomsListProxy)

        self.allRoomsListBuilder = allRoomsListBuilder
        self.allRoomsListProxy = allRoomsListProxy
    }

    private func buildAndConfigureInvitesSlidingSyncList() {
        guard invitesListBuilder == nil else {
            fatalError("This shouldn't be called more than once")
        }
        
        let listName = "Invites"
        
        let invitesListProxy = SlidingSyncListProxy(name: "Invites")

        let invitesListBuilder = SlidingSyncListBuilder(name: listName)
            .noTimelineLimit()
            .requiredState(requiredState: slidingSyncInvitesRequiredState)
            .filters(filters: slidingSyncInviteFilters)
            .syncMode(mode: .growing)
            .batchSize(batchSize: 100)
            .onceBuilt(callback: invitesListProxy)

        self.invitesListBuilder = invitesListBuilder
        self.invitesListProxy = invitesListProxy
    }

    private func buildAndConfigureNotificationsSlidingSyncList() {
        guard notificationsListBuilder == nil else {
            fatalError("This shouldn't be called more than once")
        }
        
        let notificationsListBuilder = SlidingSyncListBuilder(name: "Notifications")
            .noTimelineLimit()
            .requiredState(requiredState: slidingSyncNotificationsRequiredState)
            .filters(filters: slidingSyncNotificationsFilters)
            .syncMode(mode: .growing)
            .batchSize(batchSize: 100)
        
        self.notificationsListBuilder = notificationsListBuilder
    }

    private func buildRoomSummaryProviders() {
        guard visibleRoomsSummaryProvider == nil, allRoomsSummaryProvider == nil, invitesSummaryProvider == nil else {
            fatalError("This shouldn't be called more than once")
        }
        
        guard let visibleRoomsListProxy, let allRoomsListProxy, let invitesListProxy else {
            MXLog.error("Sliding sync view proxies unavailable")
            return
        }
        
        visibleRoomsSummaryProvider = RoomSummaryProvider(slidingSyncListProxy: visibleRoomsListProxy,
                                                          eventStringBuilder: RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID)),
                                                          name: visibleRoomsListProxy.name)
        
        allRoomsSummaryProvider = RoomSummaryProvider(slidingSyncListProxy: allRoomsListProxy,
                                                      eventStringBuilder: RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID)),
                                                      name: allRoomsListProxy.name)
        
        invitesSummaryProvider = RoomSummaryProvider(slidingSyncListProxy: invitesListProxy,
                                                     eventStringBuilder: RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID)),
                                                     name: invitesListProxy.name)
    }
    
    private lazy var slidingSyncRequiredState = [RequiredState(key: "m.room.avatar", value: ""),
                                                 RequiredState(key: "m.room.encryption", value: ""),
                                                 RequiredState(key: "m.room.power_levels", value: "")]

    private lazy var slidingSyncNotificationsRequiredState = [RequiredState(key: "m.room.member", value: "$ME"),
                                                              RequiredState(key: "m.room.power_levels", value: ""),
                                                              RequiredState(key: "m.room.name", value: "")]
    
    private lazy var slidingSyncInvitesRequiredState = [RequiredState(key: "m.room.avatar", value: ""),
                                                        RequiredState(key: "m.room.encryption", value: ""),
                                                        RequiredState(key: "m.room.member", value: "$ME"),
                                                        RequiredState(key: "m.room.canonical_alias", value: "")]
    
    private lazy var slidingSyncFilters = SlidingSyncRequestListFilters(isDm: nil,
                                                                        spaces: [],
                                                                        isEncrypted: nil,
                                                                        isInvite: false,
                                                                        isTombstoned: false,
                                                                        roomTypes: [],
                                                                        notRoomTypes: ["m.space"],
                                                                        roomNameLike: nil,
                                                                        tags: [],
                                                                        notTags: [])

    private lazy var slidingSyncNotificationsFilters = SlidingSyncRequestListFilters(isDm: nil,
                                                                                     spaces: [],
                                                                                     isEncrypted: nil,
                                                                                     isInvite: nil,
                                                                                     isTombstoned: false,
                                                                                     roomTypes: [],
                                                                                     notRoomTypes: ["m.space"],
                                                                                     roomNameLike: nil,
                                                                                     tags: [],
                                                                                     notTags: [])
    
    private lazy var slidingSyncInviteFilters = SlidingSyncRequestListFilters(isDm: nil,
                                                                              spaces: [],
                                                                              isEncrypted: nil,
                                                                              isInvite: true,
                                                                              isTombstoned: false,
                                                                              roomTypes: [],
                                                                              notRoomTypes: ["m.space"],
                                                                              roomNameLike: nil,
                                                                              tags: [],
                                                                              notTags: [])
    
    private func configureViewsPostInitialSync() {
        if let visibleRoomsListProxy {
            MXLog.info("Setting visible rooms view timeline limit to \(SlidingSyncConstants.lastMessageTimelineLimit)")
            visibleRoomsListProxy.updateVisibleRange(nil, timelineLimit: SlidingSyncConstants.lastMessageTimelineLimit)
        } else {
            MXLog.error("Visible rooms sliding sync view unavailable")
        }

        if let allRoomsListBuilder {
            MXLog.info("Registering all rooms view")
            slidingSyncTasks.append(slidingSync?.addList(listBuilder: allRoomsListBuilder))
        } else {
            MXLog.error("All rooms sliding sync view unavailable")
        }

        if let invitesListBuilder {
            MXLog.info("Registering invites view")
            slidingSyncTasks.append(slidingSync?.addList(listBuilder: invitesListBuilder))
        } else {
            MXLog.error("Invites sliding sync view unavailable")
        }

        if ServiceLocator.shared.settings.enableLocalPushNotifications {
            if let notificationsListBuilder {
                MXLog.info("Registering notifications view")
                slidingSyncTasks.append(slidingSync?.addList(listBuilder: notificationsListBuilder))
            } else {
                MXLog.error("Notifications sliding sync view unavailable")
            }
        }
    }
    
    private func roomTupleForIdentifier(_ identifier: String) -> (SlidingSyncRoom?, Room?) {
        do {
            let slidingSyncRoom = try slidingSync?.getRoom(roomId: identifier)
            let fullRoom = slidingSyncRoom?.fullRoom()

            return (slidingSyncRoom, fullRoom)
        } catch {
            MXLog.error("Failed retrieving room with identifier: \(identifier)")
            return (nil, nil)
        }
    }
    
    fileprivate func updateRestorationToken() {
        callbacks.send(.updateRestorationToken)
    }
    
    fileprivate func didReceiveAuthError(isSoftLogout: Bool) {
        callbacks.send(.receivedAuthError(isSoftLogout: isSoftLogout))
    }
    
    fileprivate func didReceiveSlidingSyncUpdate(summary: UpdateSummary) {
        callbacks.send(.receivedSyncUpdate)
    }

    fileprivate func didReceiveNotification(notification: NotificationItemProxyProtocol) {
        callbacks.send(.receivedNotification(notification))
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
