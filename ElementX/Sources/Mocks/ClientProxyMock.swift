//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        canDeactivateAccount = false
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
        
        slidingSyncVersion = .native
        availableSlidingSyncVersionsClosure = {
            []
        }
        
        trackRecentlyVisitedRoomReturnValue = .success(())
        recentlyVisitedRoomsReturnValue = .success([])
        recentConversationCounterpartsReturnValue = []
        
        getElementWellKnownReturnValue = .success(nil)
        
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
            
            return await .joined(JoinedRoomProxyMock(.init(id: room.id, name: room.name)))
        }
    }
}
