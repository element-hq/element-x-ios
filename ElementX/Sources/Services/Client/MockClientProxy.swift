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

class MockClientProxy: ClientProxyProtocol {
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    let userID: String
    let deviceID: String?
    let homeserver = ""
    let restorationToken: RestorationToken? = nil
    
    var roomSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()
    
    var inviteSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()

    var avatarURLPublisher: AnyPublisher<URL?, Never> { Empty().eraseToAnyPublisher() }

    var isSyncing: Bool { false }
    
    init(userID: String, deviceID: String? = nil, roomSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()) {
        self.userID = userID
        self.deviceID = deviceID
        self.roomSummaryProvider = roomSummaryProvider
    }

    func loadUserAvatarURL() async { }
    
    func startSync() { }
    
    func stopSync(completionHandler: () -> Void) { }

    func pauseSync() { }
    
    func directRoomForUserID(_ userID: String) async -> Result<String?, ClientProxyError> {
        .failure(.failedRetrievingDirectRoom)
    }
    
    func createDirectRoom(with userID: String, expectedRoomName: String?) async -> Result<String, ClientProxyError> {
        .failure(.failedCreatingRoom)
    }
    
    func createRoom(name: String, topic: String?, isRoomPrivate: Bool, userIDs: [String], avatarURL: URL?) async -> Result<String, ClientProxyError> {
        .failure(.failedCreatingRoom)
    }
    
    func uploadMedia(_ media: MediaInfo) async -> Result<String, ClientProxyError> {
        .failure(.failedUploadingMedia(.unknown))
    }
     
    var roomForIdentifierMocks: [String: RoomProxyMock] = .init()
    @MainActor
    func roomForIdentifier(_ identifier: String) async -> RoomProxyProtocol? {
        guard roomForIdentifierMocks[identifier] == nil else {
            return roomForIdentifierMocks[identifier]
        }
        
        guard let room = roomSummaryProvider?.roomListPublisher.value.first(where: { $0.id == identifier }) else {
            return nil
        }
    
        switch room {
        case .empty:
            return RoomProxyMock(with: .init(displayName: "Empty room"))
        case .filled(let details), .invalidated(let details):
            return RoomProxyMock(with: .init(displayName: details.name))
        }
    }
    
    func loadUserDisplayName() async -> Result<String, ClientProxyError> {
        .success("User display name")
    }
    
    func accountDataEvent<Content>(type: String) async -> Result<Content?, ClientProxyError> where Content: Decodable {
        .failure(.failedRetrievingAccountData)
    }
    
    func setAccountData<Content>(content: Content, type: String) async -> Result<Void, ClientProxyError> where Content: Encodable {
        .failure(.failedSettingAccountData)
    }
    
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        throw ClientProxyError.failedLoadingMedia
    }
    
    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        throw ClientProxyError.failedLoadingMedia
    }
    
    func loadMediaFileForSource(_ source: MediaSourceProxy, body: String?) async throws -> MediaFileHandleProxy {
        throw ClientProxyError.failedLoadingMedia
    }
    
    var sessionVerificationControllerProxyResult: Result<SessionVerificationControllerProxyProtocol, ClientProxyError>?
    func sessionVerificationControllerProxy() async -> Result<SessionVerificationControllerProxyProtocol, ClientProxyError> {
        if let sessionVerificationControllerProxyResult {
            return sessionVerificationControllerProxyResult
        } else {
            return .failure(.failedRetrievingSessionVerificationController)
        }
    }
    
    func logout() async {
        // no-op
    }
    
    var setPusherErrorToThrow: Error?
    var setPusherArgument: PusherConfiguration?
    var setPusherCalled = false

    func setPusher(with configuration: PusherConfiguration) async throws {
        if let setPusherErrorToThrow { throw setPusherErrorToThrow }
        setPusherCalled = true
        setPusherArgument = configuration
    }
    
    var searchUsersResult: Result<SearchUsersResultsProxy, ClientProxyError> = .success(.init(results: [], limited: false))
    func searchUsers(searchTerm: String, limit: UInt) async -> Result<SearchUsersResultsProxy, ClientProxyError> {
        searchUsersResult
    }
    
    var getProfileResult: Result<UserProfileProxy, ClientProxyError> = .success(.init(userID: "@a:b.com", displayName: "Some user"))
    private(set) var getProfileCalled = false
    func profile(for userID: String) async -> Result<UserProfileProxy, ClientProxyError> {
        getProfileCalled = true
        return getProfileResult
    }
    
    var notificationSettingsResult: NotificationSettingsProxyProtocol?
    func notificationSettings() -> NotificationSettingsProxyProtocol {
        if let notificationSettingsResult {
            return notificationSettingsResult
        } else {
            return NotificationSettingsProxyMock(with: .init())
        }
    }
}
