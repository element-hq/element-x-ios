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
    
    let loadingStatePublisher = CurrentValuePublisher<ClientProxyLoadingState, Never>(.notLoading)
    
    let userID: String
    let deviceID: String?
    let homeserver = ""
    let pusherNotificationClientIdentifier: String? = nil
    
    var roomSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()
    
    var alternateRoomSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()
    
    var inviteSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()

    var userAvatarURL: CurrentValuePublisher<URL?, Never> { CurrentValueSubject<URL?, Never>(nil).asCurrentValuePublisher() }
    
    var userDisplayName: CurrentValuePublisher<String?, Never> { CurrentValueSubject<String?, Never>("User display name").asCurrentValuePublisher() }
    
    var notificationSettings: NotificationSettingsProxyProtocol = NotificationSettingsProxyMock(with: .init())
    
    lazy var secureBackupController: SecureBackupControllerProtocol = {
        let secureBackupController = SecureBackupControllerMock()
        secureBackupController.underlyingRecoveryKeyState = .init(CurrentValueSubject<SecureBackupRecoveryKeyState, Never>(.enabled))
        secureBackupController.underlyingKeyBackupState = .init(CurrentValueSubject<SecureBackupKeyBackupState, Never>(.enabled))
        secureBackupController.isLastSessionReturnValue = .success(false)
        return secureBackupController
    }()

    init(userID: String, deviceID: String? = nil, roomSummaryProvider: RoomSummaryProviderProtocol? = MockRoomSummaryProvider()) {
        self.userID = userID
        self.deviceID = deviceID
        self.roomSummaryProvider = roomSummaryProvider
    }
    
    func startSync() { }

    func stopSync() { }
    
    func accountURL(action: AccountManagementAction) -> URL? {
        "https://matrix.org/account"
    }
    
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
    
    func loadUserDisplayName() async -> Result<Void, ClientProxyError> {
        .failure(.failedRetrievingUserDisplayName)
    }
    
    func setUserDisplayName(_ name: String) async -> Result<Void, ClientProxyError> {
        .failure(.failedSettingUserDisplayName)
    }
    
    func loadUserAvatarURL() async -> Result<Void, ClientProxyError> {
        .failure(.failedRetrievingUserAvatarURL)
    }
    
    func setUserAvatar(media: MediaInfo) async -> Result<Void, ClientProxyError> {
        .failure(.failedSettingUserAvatar)
    }
    
    func removeUserAvatar() async -> Result<Void, ClientProxyError> {
        .failure(.failedSettingUserAvatar)
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
    
    func logout() async -> URL? {
        nil
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
}
