//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK

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
    var knockRequestsState: KnockRequestsState = .loaded([])
    var ownUserID = RoomMemberProxyMock.mockMe.userID
    var inviter: RoomMemberProxyProtocol?
    
    var canUserInvite = true
    var canUserTriggerRoomNotification = false
    var canUserJoinCall = true
    var canUserPin = true
    
    var shouldUseAutoUpdatingTimeline = false
    var joinRule: JoinRule?
}

extension JoinedRoomProxyMock {
    @MainActor
    convenience init(_ configuration: JoinedRoomProxyMockConfiguration) {
        self.init()

        id = configuration.id
        isEncrypted = configuration.isEncrypted
        
        timeline = TimelineProxyMock(.init(isAutoUpdating: configuration.shouldUseAutoUpdatingTimeline,
                                           timelineStartReached: configuration.timelineStartReached))

        ownUserID = configuration.ownUserID
        
        infoPublisher = CurrentValueSubject(.init(roomInfo: .init(configuration))).asCurrentValuePublisher()
        membersPublisher = CurrentValueSubject(configuration.members).asCurrentValuePublisher()
        knockRequestsStatePublisher = CurrentValueSubject(configuration.knockRequestsState).asCurrentValuePublisher()
        typingMembersPublisher = CurrentValueSubject([]).asCurrentValuePublisher()
        identityStatusChangesPublisher = CurrentValueSubject([]).asCurrentValuePublisher()

        updateMembersClosure = { }
        setNameClosure = { _ in .success(()) }
        setTopicClosure = { _ in .success(()) }
        getMemberUserIDClosure = { [weak self] userID in
            guard let member = self?.membersPublisher.value.first(where: { $0.userID == userID }) else {
                return .failure(.sdkError(RoomProxyMockError.generic))
            }
            return .success(member)
        }
        
        ignoreDeviceTrustAndResendDevicesSendHandleReturnValue = .success(())
        withdrawVerificationAndResendUserIDsSendHandleReturnValue = .success(())

        flagAsUnreadReturnValue = .success(())
        markAsReadReceiptTypeReturnValue = .success(())
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
        canUserRedactOwnUserIDReturnValue = .success(true)
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
        sendTypingNotificationIsTypingReturnValue = .success(())
    }
}

extension RoomInfo {
    @MainActor init(_ configuration: JoinedRoomProxyMockConfiguration) {
        self.init(id: configuration.id,
                  creator: nil,
                  displayName: configuration.name,
                  rawName: configuration.name,
                  topic: configuration.topic,
                  avatarUrl: configuration.avatarURL?.absoluteString,
                  isDirect: configuration.isDirect,
                  isPublic: configuration.isPublic,
                  isSpace: configuration.isSpace,
                  isTombstoned: false,
                  isFavourite: false,
                  canonicalAlias: configuration.canonicalAlias,
                  alternativeAliases: [],
                  membership: .joined,
                  inviter: configuration.inviter.map { RoomMember(userId: $0.userID,
                                                                  displayName: $0.displayName,
                                                                  avatarUrl: $0.avatarURL?.absoluteString,
                                                                  membership: $0.membership,
                                                                  isNameAmbiguous: false,
                                                                  powerLevel: Int64($0.powerLevel),
                                                                  normalizedPowerLevel: Int64($0.powerLevel),
                                                                  isIgnored: $0.isIgnored,
                                                                  suggestedRoleForPowerLevel: $0.role) },
                  heroes: [],
                  activeMembersCount: UInt64(configuration.members.filter { $0.membership == .join || $0.membership == .invite }.count),
                  invitedMembersCount: UInt64(configuration.members.filter { $0.membership == .invite }.count),
                  joinedMembersCount: UInt64(configuration.members.filter { $0.membership == .join }.count),
                  userPowerLevels: [:],
                  highlightCount: 0,
                  notificationCount: 0,
                  cachedUserDefinedNotificationMode: .allMessages,
                  hasRoomCall: configuration.hasOngoingCall,
                  activeRoomCallParticipants: [],
                  isMarkedUnread: false,
                  numUnreadMessages: 0,
                  numUnreadNotifications: 0,
                  numUnreadMentions: 0,
                  pinnedEventIds: Array(configuration.pinnedEventIDs),
                  joinRule: configuration.joinRule)
    }
}
