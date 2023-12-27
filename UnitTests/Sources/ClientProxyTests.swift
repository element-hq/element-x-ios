//
// Copyright 2023 New Vector Ltd
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
@testable import ElementX
import Foundation
import MatrixRustSDK
import XCTest

class ClientProxyTests: XCTestCase {
    private var clientProxy: ClientProxyProtocol!
    
    private var clientMock: ClientMock!
    private var roomListServiceMock: RoomListServiceMock!
    private var syncServiceMock: SyncServiceMock!
    private var clientDelegate: ClientDelegate?
    private var networkMonitor: NetworkMonitorMock!
    
    private func buildRoomMock(id: String, displayName: String, roomMembers: [RoomMemberMock]) -> RoomMock {
        let roomMock = RoomMock()
        roomMock.idReturnValue = id
        roomMock.displayNameReturnValue = displayName
        roomMock.timelineReturnValue = TimelineMock()
        roomMock.pollHistoryReturnValue = TimelineMock()

        let roomMembersIterator = RoomMembersIteratorMock()
        roomMembersIterator.lenReturnValue = UInt32(roomMembers.count)
        roomMembersIterator.nextChunkChunksizeReturnValue = roomMembers
        roomMock.membersReturnValue = roomMembersIterator

        return roomMock
    }
    
    private func buildRoomListItemMock(room: RoomMock) -> RoomListItemMock {
        let roomListItem = RoomListItemMock()
        roomListItem.fullRoomReturnValue = room
        return roomListItem
    }
    
    override func setUp() async throws {
        clientMock = ClientMock()
        clientMock.getNotificationSettingsReturnValue = NotificationSettingsMock()
        
        let roomListMock = RoomListMock()
        let roomListDynamicEntriesControllerMock = RoomListDynamicEntriesControllerMock()
        roomListDynamicEntriesControllerMock.setFilterKindReturnValue = true
        let roomListEntriesWithDynamicAdaptersResult = RoomListEntriesWithDynamicAdaptersResult(controller: roomListDynamicEntriesControllerMock, entriesStream: TaskHandleMock())
        roomListMock.entriesWithDynamicAdaptersPagesizeListenerReturnValue = roomListEntriesWithDynamicAdaptersResult
        roomListMock.loadingStateListenerReturnValue = RoomListLoadingStateResult(state: .loaded(maximumNumberOfRooms: 1), stateStream: TaskHandleMock())
        
        roomListServiceMock = RoomListServiceMock()
        roomListServiceMock.roomRoomidReturnValue = RoomListItemMock()
        roomListServiceMock.allRoomsReturnValue = roomListMock
        roomListServiceMock.invitesReturnValue = roomListMock
        roomListServiceMock.stateListenerReturnValue = TaskHandleMock()
        roomListServiceMock.syncIndicatorDelaybeforeshowinginmsDelaybeforehidinginmsListenerReturnValue = TaskHandleMock()
        
        syncServiceMock = SyncServiceMock()
        syncServiceMock.roomListServiceReturnValue = roomListServiceMock
        syncServiceMock.stateListenerReturnValue = TaskHandleMock()
        
        let syncServiceBuilderMock = SyncServiceBuilderMock()
        syncServiceBuilderMock.withCrossProcessLockAppidentifierReturnValue = syncServiceBuilderMock
        syncServiceBuilderMock.finishReturnValue = syncServiceMock
        clientMock.syncServiceReturnValue = syncServiceBuilderMock
        
        clientMock.encryptionClosure = {
            let encryptionMock = EncryptionMock()
            return encryptionMock
        }
        clientMock.setDelegateDelegateReturnValue = TaskHandleMock()
        clientMock.homeserverReturnValue = "https://matrix.org"
        clientMock.userIdReturnValue = "@tom:matrix.org"
        clientMock.cachedAvatarUrlReturnValue = "/some/avatar/url"
                
        let appService = AppSettings()
        networkMonitor = NetworkMonitorMock()
        networkMonitor.underlyingReachabilityPublisher = CurrentValueSubject<NetworkMonitorReachability, Never>(.reachable).asCurrentValuePublisher()

        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.underlyingKeyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(.enabled).asCurrentValuePublisher()
        
        clientMock.setDelegateDelegateClosure = { [weak self] clientDelegate in
            self?.clientDelegate = clientDelegate
            return TaskHandleMock()
        }
        
        clientProxy = await ClientProxy(client: clientMock,
                                        backgroundTaskService: MockBackgroundTaskService(),
                                        appSettings: appService,
                                        networkMonitor: networkMonitor,
                                        secureBackupController: secureBackupController)
    }
    
    override func tearDown() async throws { }
    
    func testRoomForIdentifier() async throws {
        let roomMock = buildRoomMock(id: "!some_room_id:matrix.org",
                                     displayName: "Test room",
                                     roomMembers: [])
        
        roomListServiceMock.roomRoomidClosure = { [weak self] roomId in
            guard let self else {
                fatalError()
            }
            guard roomId == roomMock.id() else {
                throw RoomListError.RoomNotFound(roomName: roomId)
            }
            return buildRoomListItemMock(room: roomMock)
        }
                        
        let room = await clientProxy.roomForIdentifier("!some_room_id:matrix.org")
        XCTAssertNotNil(room)
        XCTAssertEqual(roomListServiceMock.roomRoomidReceivedArgument, "!some_room_id:matrix.org")
        XCTAssertEqual(roomListServiceMock.roomRoomidReceivedInvocations.count, 1)
        
        roomListServiceMock.roomRoomidReceivedArgument = nil
        roomListServiceMock.roomRoomidReceivedInvocations = []
        let roomNotFound = await clientProxy.roomForIdentifier("!another_room_id:matrix.org")
        XCTAssertNil(roomNotFound)
        XCTAssertEqual(roomListServiceMock.roomRoomidReceivedArgument, "!another_room_id:matrix.org")
        // invocation count should be 2 because roomProxy call it again after waiting for the room to be loaded
        XCTAssertEqual(roomListServiceMock.roomRoomidReceivedInvocations.count, 2)
    }
    
    func testRoomForIdentifierWaitForVisibleRoomsListLoaded() async throws {
        let roomMock = buildRoomMock(id: "!some_room_id:matrix.org",
                                     displayName: "Test room",
                                     roomMembers: [])
        
        var invocationCount = 0
        roomListServiceMock.roomRoomidClosure = { [weak self] roomId in
            defer {
                invocationCount += 1
            }
            guard let self, roomId == roomMock.id() else {
                fatalError()
            }
            if invocationCount == 0 {
                throw RoomListError.RoomNotFound(roomName: roomId)
            }
            return buildRoomListItemMock(room: roomMock)
        }
        
        let room = await clientProxy.roomForIdentifier("!some_room_id:matrix.org")
        XCTAssertNotNil(room)
        XCTAssertEqual(roomListServiceMock.roomRoomidReceivedArgument, "!some_room_id:matrix.org")
        // invocation count should be 2 because roomProxy call it again after waiting for the room to be loaded
        XCTAssertEqual(roomListServiceMock.roomRoomidReceivedInvocations.count, 2)
    }
    
    func testStartSync() async throws {
        let expectation = expectation(description: "Wait for callback")
        syncServiceMock.startClosure = {
            expectation.fulfill()
        }
                
        clientProxy.startSync()
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    func testStartSyncNetworkNotReachable() async throws {
        networkMonitor.underlyingReachabilityPublisher = CurrentValueSubject<NetworkMonitorReachability, Never>(.unreachable).asCurrentValuePublisher()
        
        clientProxy.startSync()

        try await Task.sleep(for: .milliseconds(500))
        XCTAssertFalse(syncServiceMock.startCalled)
    }
    
    func testStartSyncAfterAuthError() async throws {
        clientDelegate?.didReceiveAuthError(isSoftLogout: true)
        
        clientProxy.startSync()

        try await Task.sleep(for: .milliseconds(500))
        XCTAssertFalse(syncServiceMock.startCalled)
    }
    
    func testStopSync() async throws {
        let expectation = expectation(description: "Wait for callback")
        syncServiceMock.stopClosure = {
            expectation.fulfill()
        }
        clientProxy.stopSync()
        await fulfillment(of: [expectation], timeout: 1.0)
    }
    
    func testLogout() async throws {
        let expectation = expectation(description: "Wait for callback")
        clientMock.logoutClosure = {
            expectation.fulfill()
            return "some_url"
        }
        let url = await clientProxy.logout()
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(url, URL(string: "some_url"))
    }
    
    func testLogoutFailure() async throws {
        clientMock.logoutThrowableError = ClientError.Generic(msg: "error")
        let url = await clientProxy.logout()
        XCTAssertNil(url)
    }
    
    func testSetPusher() async throws {
        let pusherConfiguration = PusherConfiguration(identifiers: .init(pushkey: UUID().uuidString, appId: "TestAppID"), kind: .email, appDisplayName: "TestApp", deviceDisplayName: "TestDevice", profileTag: "TestProfileTag", lang: "TestLang")
        
        try await clientProxy.setPusher(with: pusherConfiguration)

        let args = clientMock.setPusherIdentifiersKindAppdisplaynameDevicedisplaynameProfiletagLangReceivedArguments
        XCTAssertEqual(args?.identifiers, pusherConfiguration.identifiers)
        XCTAssertEqual(args?.kind, pusherConfiguration.kind)
        XCTAssertEqual(args?.appDisplayName, pusherConfiguration.appDisplayName)
        XCTAssertEqual(args?.deviceDisplayName, pusherConfiguration.deviceDisplayName)
        XCTAssertEqual(args?.profileTag, pusherConfiguration.profileTag)
        XCTAssertEqual(args?.lang, pusherConfiguration.lang)
    }
    
    func testCreatePrivateRoom() async throws {
        let name = "TestPrivateRoom"
        let topic = "TestPrivateTopic"
        let userIDs: [String] = ["@tom:matrix.org", "@alice:another_host"]
        let avatarURL: URL? = nil
        clientMock.createRoomRequestReturnValue = "!test_private_room:host"

        _ = await clientProxy.createRoom(name: name, topic: topic, isRoomPrivate: true, userIDs: userIDs, avatarURL: avatarURL)
        XCTAssert(clientMock.createRoomRequestCalled)
        XCTAssertEqual(clientMock.createRoomRequestCallsCount, 1)
        let receivedParameters = clientMock.createRoomRequestReceivedArgument
        XCTAssertEqual(receivedParameters?.name, name)
        XCTAssertEqual(receivedParameters?.topic, topic)
        XCTAssertEqual(receivedParameters?.isDirect, false)
        XCTAssertEqual(receivedParameters?.visibility, .private)
        XCTAssertEqual(receivedParameters?.preset, .privateChat)
        XCTAssertEqual(receivedParameters?.invite, userIDs)
        XCTAssertEqual(receivedParameters?.avatar, avatarURL?.absoluteString)
    }
    
    func testCreatePublicRoom() async throws {
        let name = "TestPublicRoom"
        let topic = "TestPublicTopic"
        let userIDs: [String] = ["@tom:matrix.org", "@alice:another_host"]
        let avatarURL: URL? = nil
        clientMock.createRoomRequestReturnValue = "!test_public_room:host"

        _ = await clientProxy.createRoom(name: name, topic: topic, isRoomPrivate: false, userIDs: userIDs, avatarURL: avatarURL)
        XCTAssert(clientMock.createRoomRequestCalled)
        XCTAssertEqual(clientMock.createRoomRequestCallsCount, 1)
        let receivedParameters = clientMock.createRoomRequestReceivedArgument
        XCTAssertEqual(receivedParameters?.name, name)
        XCTAssertEqual(receivedParameters?.topic, topic)
        XCTAssertEqual(receivedParameters?.isDirect, false)
        XCTAssertEqual(receivedParameters?.visibility, .public)
        XCTAssertEqual(receivedParameters?.preset, .publicChat)
        XCTAssertEqual(receivedParameters?.invite, userIDs)
        XCTAssertEqual(receivedParameters?.avatar, avatarURL?.absoluteString)
    }
    
    func testCreateRoomFailure() async throws {
        let name = "TestPublicRoom"
        let topic = "TestPublicTopic"
        let userIDs: [String] = ["@tom:matrix.org", "@alice:another_host"]
        let avatarURL: URL? = nil
        clientMock.createRoomRequestThrowableError = ClientError.Generic(msg: "error")
        
        do {
            _ = try await clientProxy.createRoom(name: name, topic: topic, isRoomPrivate: false, userIDs: userIDs, avatarURL: avatarURL).get()
        } catch ClientProxyError.failedCreatingRoom {
        } catch {
            XCTFail("Invalid error")
        }
    }
}
