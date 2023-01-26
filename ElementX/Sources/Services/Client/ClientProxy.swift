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

private class WeakClientProxyWrapper: ClientDelegate {
    private weak var clientProxy: ClientProxy?
    
    init(clientProxy: ClientProxy) {
        self.clientProxy = clientProxy
    }
    
    // MARK: - ClientDelegate
    
    func didReceiveSyncUpdate() { }

    func didReceiveAuthError(isSoftLogout: Bool) {
        MXLog.error("Received authentication error, softlogout=\(isSoftLogout)")
        clientProxy?.didReceiveAuthError(isSoftLogout: isSoftLogout)
    }

    func didUpdateRestoreToken() {
        MXLog.info("Did update restoration token")
        clientProxy?.didUpdateRestoreToken()
    }
}

class ClientProxy: ClientProxyProtocol {
    private let client: ClientProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private var sessionVerificationControllerProxy: SessionVerificationControllerProxy?
    private let mediaLoader: MediaLoaderProtocol
    private let clientQueue: DispatchQueue
    
    private var slidingSyncObserverToken: StoppableSpawn?
    private var slidingSync: SlidingSync?
    
    var visibleRoomsSlidingSyncView: SlidingSyncView?
    var visibleRoomsSummaryProvider: RoomSummaryProviderProtocol?
    
    var allRoomsSlidingSyncView: SlidingSyncView?
    var allRoomsSummaryProvider: RoomSummaryProviderProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    private var visibleRoomsViewProxyStateObservationToken: AnyCancellable?
    
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
        
        client.setDelegate(delegate: WeakClientProxyWrapper(clientProxy: self))
        
        configureSlidingSync()
    }
    
    var userID: String {
        do {
            return try client.userId()
        } catch {
            MXLog.error("Failed retrieving room info with error: \(error)")
            return "Unknown user identifier"
        }
    }

    var isSoftLogout: Bool {
        client.isSoftLogout()
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
    
    func startSync() {
        MXLog.info("Starting sync")
        guard !client.isSoftLogout(), slidingSyncObserverToken == nil else {
            return
        }
        
        slidingSyncObserverToken = slidingSync?.sync()
    }
    
    func stopSync() {
        MXLog.info("Stopping sync")
        slidingSyncObserverToken?.cancel()
        slidingSyncObserverToken = nil
    }
    
    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol? {
        let (slidingSyncRoom, room) = await Task.dispatch(on: clientQueue) {
            self.roomTupleForIdentifier(identifier)
        }

        guard let slidingSyncRoom, let room else {
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
    
    func loadUserAvatarURL() async -> Result<URL, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let urlString = try self.client.avatarUrl()
                
                guard let url = URL(string: urlString) else {
                    MXLog.error("Invalid avatar URL string: \(String(describing: urlString))")
                    return .failure(.failedRetrievingAvatarURL)
                }
                 
                return .success(url)
            } catch {
                return .failure(.failedRetrievingAvatarURL)
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

    // swiftlint:disable:next function_parameter_count
    func setPusher(pushkey: String,
                   kind: PusherKind?,
                   appId: String,
                   appDisplayName: String,
                   deviceDisplayName: String,
                   profileTag: String?,
                   lang: String,
                   url: URL?,
                   format: PushFormat?,
                   defaultPayload: [AnyHashable: Any]?) async throws {
//        let defaultPayloadString = jsonString(from: defaultPayload)
//        try await Task.dispatch(on: .global()) {
//            try self.client.setPusher(pushkey: pushkey,
//                                      kind: kind?.rustValue,
//                                      appId: appId,
//                                      appDisplayName: appDisplayName,
//                                      deviceDisplayName: deviceDisplayName,
//                                      profileTag: profileTag,
//                                      lang: lang,
//                                      url: url,
//                                      format: format?.rustValue,
//                                      defaultPayload: defaultPayloadString)
//        }
    }
    
    // MARK: Private
    
    private func restartSync() {
        MXLog.info("Restarting sync")
        stopSync()
        startSync()
    }
    
    private func configureSlidingSync() {
        guard slidingSync == nil else {
            fatalError("This shouldn't be called more than once")
        }
        
        do {
            let slidingSyncBuilder = try client.slidingSync().homeserver(url: ServiceLocator.shared.settings.slidingSyncProxyBaseURLString)
            
            // Build the visibleRoomsSlidingSyncView here so that it can take advantage of the SS builder cold cache
            // We will still register the allRoomsSlidingSyncView later, and than will have no cache
            let visibleRoomsView = try SlidingSyncViewBuilder()
                .timelineLimit(limit: 20)
                .requiredState(requiredState: slidingSyncRequiredState)
                .filters(filters: slidingSyncFilters)
                .name(name: "CurrentlyVisibleRooms")
                .syncMode(mode: .selective)
                .addRange(from: 0, to: 20)
                .sendUpdatesForItems(enable: true)
                .build()
            
            let slidingSync = try slidingSyncBuilder
                .addView(v: visibleRoomsView)
                .withCommonExtensions()
                .coldCache(name: "ElementX")
                .build()
            
            self.slidingSync = slidingSync
            
            buildAndConfigureVisibleRoomsSlidingSyncView(slidingSync: slidingSync, visibleRoomsView: visibleRoomsView)
            buildAndConfigureAllRoomsSlidingSyncView(slidingSync: slidingSync)
        } catch {
            MXLog.error("Failed building sliding sync with error: \(error)")
        }
    }
    
    private func buildAndConfigureVisibleRoomsSlidingSyncView(slidingSync: SlidingSyncProtocol, visibleRoomsView: SlidingSyncView) {
        let visibleRoomsViewProxy = SlidingSyncViewProxy(slidingSync: slidingSync, slidingSyncView: visibleRoomsView)
        
        visibleRoomsSummaryProvider = RoomSummaryProvider(slidingSyncViewProxy: visibleRoomsViewProxy,
                                                          eventStringBuilder: RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID)))
        
        visibleRoomsSlidingSyncView = visibleRoomsView
        
        // Changes to the visibleRoomsSlidingSyncView range need to restart the connection to be applied
        visibleRoomsViewProxy.visibleRangeUpdatePublisher.sink { [weak self] in
            self?.restartSync()
        }
        .store(in: &cancellables)
        
        // The allRoomsSlidingSyncView will be registered as soon as the visibleRoomsSlidingSyncView receives its first update
        visibleRoomsViewProxyStateObservationToken = visibleRoomsViewProxy.diffPublisher.sink { [weak self] _ in
            MXLog.info("Visible rooms view received first update, registering all rooms view")
            self?.registerAllRoomSlidingSyncView()
            self?.visibleRoomsViewProxyStateObservationToken = nil
        }
    }
    
    private func buildAndConfigureAllRoomsSlidingSyncView(slidingSync: SlidingSyncProtocol) {
        guard allRoomsSlidingSyncView == nil else {
            fatalError("This shouldn't be called more than once")
        }
        
        do {
            let allRoomsView = try SlidingSyncViewBuilder()
                .noTimelineLimit()
                .requiredState(requiredState: slidingSyncRequiredState)
                .filters(filters: slidingSyncFilters)
                .name(name: "AllRooms")
                .syncMode(mode: .growingFullSync)
                .batchSize(batchSize: 100)
                .roomLimit(limit: 500)
                .sendUpdatesForItems(enable: true)
                .build()
            
            let allRoomsViewProxy = SlidingSyncViewProxy(slidingSync: slidingSync, slidingSyncView: allRoomsView)
            
            allRoomsSummaryProvider = RoomSummaryProvider(slidingSyncViewProxy: allRoomsViewProxy,
                                                          eventStringBuilder: RoomEventStringBuilder(stateEventStringBuilder: RoomStateEventStringBuilder(userID: userID)))
            
            allRoomsSlidingSyncView = allRoomsView
            
        } catch {
            MXLog.error("Failed building the all rooms sliding sync view with error: \(error)")
        }
    }
    
    private lazy var slidingSyncRequiredState = [RequiredState(key: "m.room.avatar", value: ""),
                                                 RequiredState(key: "m.room.encryption", value: "")]
    
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
    
    private func registerAllRoomSlidingSyncView() {
        guard let allRoomsSlidingSyncView else {
            MXLog.error("All rooms sliding sync view unavailable")
            return
        }
        
        _ = slidingSync?.addView(view: allRoomsSlidingSyncView)
        restartSync()
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
    
    fileprivate func didReceiveAuthError(isSoftLogout: Bool) {
        callbacks.send(.receivedAuthError(isSoftLogout: isSoftLogout))
    }

    fileprivate func didUpdateRestoreToken() {
        callbacks.send(.updatedRestoreToken)
    }
    
    /// Convenience method to get the json string of an Encodable
    private func jsonString(from dictionary: [AnyHashable: Any]?) -> String? {
        guard let dictionary,
              let data = try? JSONSerialization.data(withJSONObject: dictionary,
                                                     options: [.fragmentsAllowed]) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
}

extension ClientProxy: MediaLoaderProtocol {
    func mediaSourceForURL(_ url: URL) async -> MediaSourceProxy {
        await mediaLoader.mediaSourceForURL(url)
    }

    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await mediaLoader.loadMediaContentForSource(source)
    }

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await mediaLoader.loadMediaThumbnailForSource(source, width: width, height: height)
    }
}
