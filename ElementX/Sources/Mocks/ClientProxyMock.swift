//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

struct ClientProxyMockConfiguration {
    var homeserver = ""
    var userIDServerName: String?
    var userID: String = RoomMemberProxyMock.mockMe.userID
    var deviceID: String?
    var roomSummaryProvider: RoomSummaryProviderProtocol = RoomSummaryProviderMock(.init())
    var spaceServiceConfiguration: SpaceServiceProxyMock.Configuration = .init()
    var roomPreviews: [RoomPreviewProxyProtocol]?
    var roomDirectorySearchProxy: RoomDirectorySearchProxyProtocol?
    var overrides = Overrides()
    
    var recoveryState: SecureBackupRecoveryState = .enabled
    
    var notificationSettings = NotificationSettingsProxyMock(with: .init())
    
    var timelineMediaVisibility = TimelineMediaVisibility.always
    var hideInviteAvatars = false
    
    var maxMediaUploadSize: UInt = 100 * 1024 * 1024
    
    class Overrides {
        var joinedRoomIDs: Set<String> = []
    }
}

enum ClientProxyMockError: Error {
    case generic
}

extension ClientProxyMock {
    convenience init(_ configuration: ClientProxyMockConfiguration) {
        self.init()
        
        userID = configuration.userID
        deviceID = configuration.deviceID
        
        homeserver = configuration.homeserver
        userIDServerName = configuration.userIDServerName
        
        roomSummaryProvider = configuration.roomSummaryProvider
        alternateRoomSummaryProvider = RoomSummaryProviderMock(.init())
        staticRoomSummaryProvider = RoomSummaryProviderMock(.init())
        
        roomDirectorySearchProxyReturnValue = configuration.roomDirectorySearchProxy
        
        actionsPublisher = PassthroughSubject<ClientProxyAction, Never>().eraseToAnyPublisher()
        loadingStatePublisher = .init(.notLoading)
        verificationStatePublisher = .init(.unknown)
        homeserverReachabilityPublisher = .init(.reachable)
        
        userAvatarURLPublisher = .init(nil)
        userDisplayNamePublisher = .init("User display name")
        
        ignoredUsersPublisher = .init([RoomMemberProxyMock].allMembers.map(\.userID))
        
        notificationSettings = configuration.notificationSettings
        
        isOnlyDeviceLeftReturnValue = .success(false)
        accountURLActionReturnValue = "https://matrix.org/account"
        canDeactivateAccount = false
        directRoomForUserIDReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        createDirectRoomWithExpectedRoomNameReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        createRoomNameTopicIsRoomPrivateIsKnockingOnlyUserIDsAvatarURLAliasLocalPartReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        canJoinRoomWithReturnValue = true
        joinRoomViaClosure = { roomID, _ in
            configuration.overrides.joinedRoomIDs.insert(roomID)
            return .success(())
        }
        joinRoomAliasReturnValue = .success(())
        uploadMediaReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        loadUserDisplayNameReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        setUserDisplayNameReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        loadUserAvatarURLReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        setUserAvatarMediaReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        removeUserAvatarReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        isAliasAvailableReturnValue = .success(true)
        searchUsersSearchTermLimitReturnValue = .success(.init(results: [], limited: false))
        profileForReturnValue = .success(.init(userID: "@a:b.com", displayName: "Some user"))
        ignoreUserReturnValue = .success(())
        unignoreUserReturnValue = .success(())
        
        trackRecentlyVisitedRoomReturnValue = .success(())
        recentlyVisitedRoomsReturnValue = .success([])
        recentConversationCounterpartsReturnValue = []
        
        let mediaLoader = MediaLoaderMock()
        mediaLoader.loadMediaContentForSourceThrowableError = ClientProxyError.sdkError(ClientProxyMockError.generic)
        mediaLoader.loadMediaThumbnailForSourceWidthHeightThrowableError = ClientProxyError.sdkError(ClientProxyMockError.generic)
        mediaLoader.loadMediaFileForSourceFilenameThrowableError = ClientProxyError.sdkError(ClientProxyMockError.generic)
        self.mediaLoader = mediaLoader
        
        secureBackupController = SecureBackupControllerMock(.init(recoveryState: configuration.recoveryState))
        resetIdentityReturnValue = .success(IdentityResetHandleSDKMock(.init()))
        
        spaceService = SpaceServiceProxyMock(configuration.spaceServiceConfiguration)
        
        roomForIdentifierClosure = { [weak self] identifier in
            if let room = self?.roomSummaryProvider.roomListPublisher.value.first(where: { $0.id == identifier }) {
                let joinedRoomIDs = configuration.overrides.joinedRoomIDs
                switch room.joinRequestType {
                case .invite where !joinedRoomIDs.contains(room.id):
                    let roomProxy = await InvitedRoomProxyMock(.init(id: room.id, name: room.name, isSpace: room.isSpace))
                    return .invited(roomProxy)
                case .knock where !joinedRoomIDs.contains(room.id):
                    let roomProxy = await KnockedRoomProxyMock(.init(id: room.id, name: room.name))
                    return .knocked(roomProxy)
                default:
                    let roomProxy = await JoinedRoomProxyMock(.init(id: room.id, name: room.name, isSpace: room.isSpace))
                    roomProxy.loadOrFetchEventDetailsForReturnValue = .success(TimelineEventSDKMock())
                    return .joined(roomProxy)
                }
            } else if let spaceRoomProxy = configuration.spaceServiceConfiguration.joinedSpaces.first(where: { $0.id == identifier }) {
                let roomProxy = await JoinedRoomProxyMock(.init(id: spaceRoomProxy.id, name: spaceRoomProxy.name, isSpace: spaceRoomProxy.isSpace))
                roomProxy.loadOrFetchEventDetailsForReturnValue = .success(TimelineEventSDKMock())
                return .joined(roomProxy)
            } else {
                return nil
            }
        }
        
        if let roomPreviews = configuration.roomPreviews {
            roomPreviewForIdentifierViaClosure = { roomID, _ in
                if let preview = roomPreviews.first(where: { $0.info.id == roomID }) {
                    .success(preview)
                } else {
                    .failure(.roomPreviewIsPrivate)
                }
            }
        }
        
        userIdentityForReturnValue = .success(UserIdentityProxyMock(configuration: .init()))
        
        underlyingIsReportRoomSupported = true
        underlyingIsLiveKitRTCSupported = true
        
        underlyingTimelineMediaVisibilityPublisher = CurrentValueSubject<TimelineMediaVisibility, Never>(configuration.timelineMediaVisibility).asCurrentValuePublisher()
        underlyingHideInviteAvatarsPublisher = CurrentValueSubject<Bool, Never>(configuration.hideInviteAvatars).asCurrentValuePublisher()
        
        underlyingMaxMediaUploadSize = .success(configuration.maxMediaUploadSize)
    }
}
