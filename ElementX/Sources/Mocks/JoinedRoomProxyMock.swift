//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

enum RoomProxyMockError: Error {
    case generic
}

@MainActor
struct JoinedRoomProxyMockConfiguration {
    var id = UUID().uuidString
    var name: String?
    var topic: String?
    var avatarURL: URL?
    var isDirect = false
    var isSpace = false
    var isPublic = false
    var isEncrypted = true
    var hasOngoingCall = true
    var canonicalAlias: String?
    var pinnedEventIDs: Set<String> = []
    
    var timelineStartReached = false
    
    var members: [RoomMemberProxyMock] = .allMembers
    var ownUserID = RoomMemberProxyMock.mockMe.userID
    var inviter: RoomMemberProxyProtocol?
    
    var canUserInvite = true
    var canUserTriggerRoomNotification = false
    var canUserJoinCall = true
    var canUserPin = true
    
    var shouldUseAutoUpdatingTimeline = false
}

extension JoinedRoomProxyMock {
    @MainActor
    convenience init(_ configuration: JoinedRoomProxyMockConfiguration) {
        self.init()

        id = configuration.id
        name = configuration.name
        topic = configuration.topic
        avatar = .room(id: configuration.id, name: configuration.name, avatarURL: configuration.avatarURL) // Note: This doesn't replicate the real proxy logic.
        avatarURL = configuration.avatarURL
        isDirect = configuration.isDirect
        isSpace = configuration.isSpace
        isPublic = configuration.isPublic
        isEncrypted = configuration.isEncrypted
        hasOngoingCall = configuration.hasOngoingCall
        canonicalAlias = configuration.canonicalAlias
        
        underlyingPinnedEventIDs = configuration.pinnedEventIDs
        
        let timeline = TimelineProxyMock()
        timeline.sendMessageEventContentReturnValue = .success(())
        timeline.paginateBackwardsRequestSizeReturnValue = .success(())
        timeline.paginateForwardsRequestSizeReturnValue = .success(())
        timeline.sendReadReceiptForTypeReturnValue = .success(())
        
        if configuration.shouldUseAutoUpdatingTimeline {
            timeline.underlyingTimelineProvider = AutoUpdatingRoomTimelineProviderMock()
        } else {
            let timelineProvider = RoomTimelineProviderMock()
            timelineProvider.paginationState = .init(backward: configuration.timelineStartReached ? .timelineEndReached : .idle, forward: .timelineEndReached)
            timelineProvider.underlyingMembershipChangePublisher = PassthroughSubject().eraseToAnyPublisher()
            timeline.underlyingTimelineProvider = timelineProvider
        }
        
        self.timeline = timeline

        ownUserID = configuration.ownUserID
        
        membersPublisher = CurrentValueSubject(configuration.members).asCurrentValuePublisher()
        typingMembersPublisher = CurrentValueSubject([]).asCurrentValuePublisher()
        
        joinedMembersCount = configuration.members.filter { $0.membership == .join }.count
        activeMembersCount = configuration.members.filter { $0.membership == .join || $0.membership == .invite }.count

        updateMembersClosure = { }
        underlyingActionsPublisher = Empty(completeImmediately: false).eraseToAnyPublisher()
        setNameClosure = { _ in .success(()) }
        setTopicClosure = { _ in .success(()) }
        getMemberUserIDClosure = { [weak self] userID in
            guard let member = self?.membersPublisher.value.first(where: { $0.userID == userID }) else {
                return .failure(.sdkError(RoomProxyMockError.generic))
            }
            return .success(member)
        }
        
        resendItemIDReturnValue = .success(())
        ignoreDeviceTrustAndResendDevicesItemIDReturnValue = .success(())
        withdrawVerificationAndResendUserIDsItemIDReturnValue = .success(())

        flagAsUnreadReturnValue = .success(())
        markAsReadReceiptTypeReturnValue = .success(())
        underlyingIsFavourite = false
        flagAsFavouriteReturnValue = .success(())
        
        powerLevelsReturnValue = .success(.mock)
        applyPowerLevelChangesReturnValue = .success(())
        resetPowerLevelsReturnValue = .success(.mock)
        suggestedRoleForClosure = { [weak self] userID in
            guard case .success(let member) = await self?.getMember(userID: userID) else {
                return .failure(.sdkError(RoomProxyMockError.generic))
            }
            return .success(member.role)
        }
        updatePowerLevelsForUsersReturnValue = .success(())
        canUserUserIDSendStateEventClosure = { [weak self] userID, _ in
            .success(self?.membersPublisher.value.first { $0.userID == userID }?.role ?? .user != .user)
        }
        canUserInviteUserIDReturnValue = .success(configuration.canUserInvite)
        canUserRedactOtherUserIDReturnValue = .success(false)
        canUserRedactOwnUserIDReturnValue = .success(false)
        canUserKickUserIDClosure = { [weak self] userID in
            .success(self?.membersPublisher.value.first { $0.userID == userID }?.role ?? .user != .user)
        }
        canUserBanUserIDClosure = { [weak self] userID in
            .success(self?.membersPublisher.value.first { $0.userID == userID }?.role ?? .user != .user)
        }
        canUserTriggerRoomNotificationUserIDReturnValue = .success(configuration.canUserTriggerRoomNotification)
        canUserJoinCallUserIDReturnValue = .success(configuration.canUserJoinCall)
        canUserPinOrUnpinUserIDReturnValue = .success(configuration.canUserPin)
        
        kickUserReturnValue = .success(())
        banUserReturnValue = .success(())
        unbanUserReturnValue = .success(())
        
        let widgetDriver = ElementCallWidgetDriverMock()
        widgetDriver.underlyingMessagePublisher = .init()
        widgetDriver.underlyingActions = PassthroughSubject().eraseToAnyPublisher()
        
        guard let url = URL(string: "https://call.element.dev/\(UUID().uuidString)#?appPrompt=false") else {
            fatalError()
        }
        
        widgetDriver.startBaseURLClientIDColorSchemeReturnValue = .success(url)
        
        elementCallWidgetDriverDeviceIDReturnValue = widgetDriver
        sendCallNotificationIfNeededReturnValue = .success(())
        
        matrixToPermalinkReturnValue = .success(.homeDirectory)
        matrixToEventPermalinkReturnValue = .success(.homeDirectory)
        loadDraftReturnValue = .success(nil)
        clearDraftReturnValue = .success(())
    }
}
