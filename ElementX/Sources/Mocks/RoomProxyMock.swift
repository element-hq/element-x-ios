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
import Foundation

@MainActor
struct RoomProxyMockConfiguration {
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
    
    var timelineStartReached = false
    
    var members: [RoomMemberProxyMock] = .allMembers
    var ownUserID = RoomMemberProxyMock.mockMe.userID
    
    var canUserInvite = true
    var canUserTriggerRoomNotification = false
    var canUserJoinCall = true
    
    var shouldUseAutoUpdatingTimeline = false
}

enum RoomProxyMockError: Error {
    case generic
}

extension RoomProxyMock {
    @MainActor
    convenience init(_ configuration: RoomProxyMockConfiguration) {
        self.init()

        id = configuration.id
        name = configuration.name
        topic = configuration.topic
        avatar = .room(id: configuration.id, name: configuration.name, avatarURL: configuration.avatarURL) // TODO: What happens for the logic in here?
        avatarURL = configuration.avatarURL
        isDirect = configuration.isDirect
        isSpace = configuration.isSpace
        isPublic = configuration.isPublic
        isEncrypted = configuration.isEncrypted
        hasOngoingCall = configuration.hasOngoingCall
        canonicalAlias = configuration.canonicalAlias
        
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
        membership = .joined
        
        membersPublisher = CurrentValueSubject(configuration.members).asCurrentValuePublisher()
        typingMembersPublisher = CurrentValueSubject([]).asCurrentValuePublisher()
        
        joinedMembersCount = configuration.members.filter { $0.membership == .join }.count
        activeMembersCount = configuration.members.filter { $0.membership == .join || $0.membership == .invite }.count

        updateMembersClosure = { }
        acceptInvitationClosure = { .success(()) }
        underlyingActionsPublisher = Empty(completeImmediately: false).eraseToAnyPublisher()
        setNameClosure = { _ in .success(()) }
        setTopicClosure = { _ in .success(()) }
        getMemberUserIDClosure = { [weak self] userID in
            guard let member = self?.membersPublisher.value.first(where: { $0.userID == userID }) else {
                return .failure(.sdkError(RoomProxyMockError.generic))
            }
            return .success(member)
        }

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
        
        kickUserReturnValue = .success(())
        banUserReturnValue = .success(())
        unbanUserReturnValue = .success(())
        
        let widgetDriver = ElementCallWidgetDriverMock()
        widgetDriver.underlyingMessagePublisher = .init()
        widgetDriver.underlyingActions = PassthroughSubject().eraseToAnyPublisher()
        
        guard let url = URL(string: "https://call.element.dev/\(UUID().uuidString)#?appPrompt=false") else {
            fatalError()
        }
        
        widgetDriver.startBaseURLClientIDReturnValue = .success(url)
        
        elementCallWidgetDriverReturnValue = widgetDriver
        sendCallNotificationIfNeeededReturnValue = .success(())
        
        matrixToPermalinkReturnValue = .success(.homeDirectory)
        matrixToEventPermalinkReturnValue = .success(.homeDirectory)
        loadDraftReturnValue = .success(nil)
        clearDraftReturnValue = .success(())
    }
}
