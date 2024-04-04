//
// Copyright 2024 New Vector Ltd
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

struct ClientProxyMockConfiguration {
    var userID: String = RoomMemberProxyMock.mockMe.userID
    var deviceID: String?
    var roomSummaryProvider: RoomSummaryProviderProtocol? = RoomSummaryProviderMock(.init())
    var roomDirectorySearchProxy: RoomDirectorySearchProxyProtocol?
}

enum ClientProxyMockError: Error {
    case generic
}

extension ClientProxyMock {
    convenience init(_ configuration: ClientProxyMockConfiguration) {
        self.init()
        
        userID = configuration.userID
        deviceID = configuration.deviceID
        
        homeserver = ""
        
        roomSummaryProvider = configuration.roomSummaryProvider
        alternateRoomSummaryProvider = RoomSummaryProviderMock(.init())
        inviteSummaryProvider = RoomSummaryProviderMock(.init())
        
        roomDirectorySearchProxyReturnValue = configuration.roomDirectorySearchProxy
        
        actionsPublisher = PassthroughSubject<ClientProxyAction, Never>().eraseToAnyPublisher()
        loadingStatePublisher = CurrentValuePublisher<ClientProxyLoadingState, Never>(.notLoading)
        verificationStatePublisher = CurrentValuePublisher<SessionVerificationState, Never>(.unknown)
        
        userAvatarURLPublisher = CurrentValueSubject<URL?, Never>(nil).asCurrentValuePublisher()
        
        userDisplayNamePublisher = CurrentValueSubject<String?, Never>("User display name").asCurrentValuePublisher()
        
        ignoredUsersPublisher = CurrentValueSubject<[String]?, Never>([RoomMemberProxyMock].allMembers.map(\.userID)).asCurrentValuePublisher()
        
        notificationSettings = NotificationSettingsProxyMock(with: .init())
        
        isOnlyDeviceLeftReturnValue = .success(false)
        accountURLActionReturnValue = "https://matrix.org/account"
        directRoomForUserIDReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        createDirectRoomWithExpectedRoomNameReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        createRoomNameTopicIsRoomPrivateUserIDsAvatarURLReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        uploadMediaReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        loadUserDisplayNameReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        setUserDisplayNameReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        loadUserAvatarURLReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        setUserAvatarMediaReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        removeUserAvatarReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        logoutReturnValue = nil
        searchUsersSearchTermLimitReturnValue = .success(.init(results: [], limited: false))
        profileForReturnValue = .success(.init(userID: "@a:b.com", displayName: "Some user"))
        sessionVerificationControllerProxyReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        ignoreUserReturnValue = .success(())
        unignoreUserReturnValue = .success(())
        
        loadMediaContentForSourceThrowableError = ClientProxyError.sdkError(ClientProxyMockError.generic)
        loadMediaThumbnailForSourceWidthHeightThrowableError = ClientProxyError.sdkError(ClientProxyMockError.generic)
        loadMediaFileForSourceBodyThrowableError = ClientProxyError.sdkError(ClientProxyMockError.generic)
        
        secureBackupController = {
            let secureBackupController = SecureBackupControllerMock()
            secureBackupController.underlyingRecoveryState = .init(CurrentValueSubject<SecureBackupRecoveryState, Never>(.enabled))
            secureBackupController.underlyingKeyBackupState = .init(CurrentValueSubject<SecureBackupKeyBackupState, Never>(.enabled))
            return secureBackupController
        }()
        
        roomForIdentifierClosure = { [weak self] identifier in
            guard let room = self?.roomSummaryProvider?.roomListPublisher.value.first(where: { $0.id == identifier }) else {
                return nil
            }
            
            let roomID = room.id ?? UUID().uuidString
        
            switch room {
            case .empty:
                return await RoomProxyMock(with: .init(name: "Empty room"))
            case .filled(let details), .invalidated(let details):
                return await RoomProxyMock(with: .init(id: roomID, name: details.name))
            }
        }
    }
}
