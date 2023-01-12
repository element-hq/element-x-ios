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

private class WeakClientProxyWrapper: ClientDelegate, SlidingSyncObserver {
    private weak var clientProxy: ClientProxy?
    
    init(clientProxy: ClientProxy) {
        self.clientProxy = clientProxy
    }
    
    // MARK: - ClientDelegate
    
    func didReceiveSyncUpdate() { }

    func didReceiveAuthError(isSoftLogout: Bool) {
        clientProxy?.didReceiveAuthError(isSoftLogout: isSoftLogout)
    }

    func didUpdateRestoreToken() {
        clientProxy?.didUpdateRestoreToken()
    }
    
    // MARK: - SlidingSyncDelegate
    
    func didReceiveSyncUpdate(summary: UpdateSummary) {
        clientProxy?.didReceiveSlidingSyncUpdate(summary: summary)
    }
}

class ClientProxy: ClientProxyProtocol {
    private let client: ClientProtocol
    private let backgroundTaskService: BackgroundTaskServiceProtocol
    private var sessionVerificationControllerProxy: SessionVerificationControllerProxy?
    private let mediaProxy: MediaProxyProtocol
    private let clientQueue: DispatchQueue
    
    private var slidingSyncObserverToken: StoppableSpawn?
    private var slidingSync: SlidingSync?
    
    var visibleRoomsSlidingSyncView: SlidingSyncViewProtocol?
    var visibleRoomsSummaryProvider: RoomSummaryProviderProtocol?
    
    var allRoomsSlidingSyncView: SlidingSyncViewProtocol?
    var allRoomsSummaryProvider: RoomSummaryProviderProtocol?
    
    private var cancellables = Set<AnyCancellable>()
    
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
        
        mediaProxy = MediaProxy(client: client, clientQueue: clientQueue)
        
        client.setDelegate(delegate: WeakClientProxyWrapper(clientProxy: self))
        
        configureSlidingSync()
    }
    
    var userIdentifier: String {
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
        guard !client.isSoftLogout() else {
            return
        }
        
        slidingSync?.setObserver(observer: WeakClientProxyWrapper(clientProxy: self))
        slidingSyncObserverToken = slidingSync?.sync()
    }
    
    func stopSync() {
        client.setDelegate(delegate: nil)
        
        slidingSyncObserverToken?.cancel()
        slidingSync?.setObserver(observer: nil)
    }
    
    func restartSync() {
        slidingSyncObserverToken?.cancel()
        slidingSyncObserverToken = slidingSync?.sync()
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
        
    func loadUserAvatarURLString() async -> Result<String, ClientProxyError> {
        await Task.dispatch(on: clientQueue) {
            do {
                let avatarURL = try self.client.avatarUrl()
                return .success(avatarURL)
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
                   url: String?,
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
    
    private func configureSlidingSync() {
        do {
            let slidingSyncBuilder = try client.slidingSync().homeserver(url: ServiceLocator.shared.settings.slidingSyncProxyBaseURLString)
            
            let slidingSync = try slidingSyncBuilder
                .withCommonExtensions()
                .coldCache(name: "ElementX")
                .build()
            self.slidingSync = slidingSync
            
            configureSlidingSyncViews(slidingSync: slidingSync)
            
            guard let visibleRoomsSlidingSyncView else {
                MXLog.error("Visible rooms sliding sync view unavailable")
                return
            }
            
            registerSlidingSyncView(visibleRoomsSlidingSyncView)
            
        } catch {
            MXLog.error("Failed building sliding sync with error: \(error)")
        }
    }
    
    // swiftlint:disable:next function_body_length
    private func configureSlidingSyncViews(slidingSync: SlidingSyncProtocol) {
        let requiredState = [RequiredState(key: "m.room.avatar", value: ""),
                             RequiredState(key: "m.room.encryption", value: "")]
        
        let filters = SlidingSyncRequestListFilters(isDm: nil,
                                                    spaces: [],
                                                    isEncrypted: nil,
                                                    isInvite: false,
                                                    isTombstoned: false,
                                                    roomTypes: [],
                                                    notRoomTypes: ["m.space"],
                                                    roomNameLike: nil,
                                                    tags: [],
                                                    notTags: [])
        
        do {
            let visibleRoomsView = try SlidingSyncViewBuilder()
                .timelineLimit(limit: 20)
                .requiredState(requiredState: requiredState)
                .filters(filters: filters)
                .name(name: "CurrentlyVisibleRooms")
                .syncMode(mode: .selective)
                .addRange(from: 0, to: 20)
                .build()
            
            let allRoomsView = try SlidingSyncViewBuilder()
                .noTimelineLimit()
                .requiredState(requiredState: requiredState)
                .filters(filters: filters)
                .name(name: "AllRooms")
                .syncMode(mode: .growingFullSync)
                .batchSize(batchSize: 100)
                .roomLimit(limit: 500)
                .build()
            
            let visibleRoomsViewProxy = SlidingSyncViewProxy(slidingSync: slidingSync, slidingSyncView: visibleRoomsView)
            
            let allRoomsViewProxy = SlidingSyncViewProxy(slidingSync: slidingSync, slidingSyncView: allRoomsView)
            
            visibleRoomsSummaryProvider = RoomSummaryProvider(slidingSyncViewProxy: visibleRoomsViewProxy,
                                                              roomMessageFactory: RoomMessageFactory())
            
            allRoomsSummaryProvider = RoomSummaryProvider(slidingSyncViewProxy: allRoomsViewProxy,
                                                          roomMessageFactory: RoomMessageFactory())
            
            visibleRoomsViewProxy.visibleRangeUpdatePublisher.sink { [weak self] in
                self?.restartSync()
            }
            .store(in: &cancellables)
            
            visibleRoomsViewProxy.statePublisher.sink { [weak self] state in
                if state == .live {
                    self?.registerAllRoomSlidingSyncView()
                }
            }
            .store(in: &cancellables)
            
            visibleRoomsSlidingSyncView = visibleRoomsView
            allRoomsSlidingSyncView = allRoomsView
            
        } catch {
            MXLog.error("Failed building sliding sync views with error: \(error)")
        }
    }
    
    private func registerAllRoomSlidingSyncView() {
        guard let allRoomsSlidingSyncView else {
            MXLog.error("All rooms sliding sync view unavailable")
            return
        }
        
        registerSlidingSyncView(allRoomsSlidingSyncView)
    }
    
    private func registerSlidingSyncView(_ view: SlidingSyncViewProtocol) {
        
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
    
    fileprivate func didReceiveSlidingSyncUpdate(summary: UpdateSummary) {
        visibleRoomsSummaryProvider?.updateRoomsWithIdentifiers(summary.rooms)
        allRoomsSummaryProvider?.updateRoomsWithIdentifiers(summary.rooms)
        
        callbacks.send(.receivedSyncUpdate)
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

extension ClientProxy: MediaProxyProtocol {
    func mediaSourceForURLString(_ urlString: String) -> MediaSourceProxy {
        mediaProxy.mediaSourceForURLString(urlString)
    }

    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await mediaProxy.loadMediaContentForSource(source)
    }

    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await mediaProxy.loadMediaThumbnailForSource(source, width: width, height: height)
    }
}
