//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct HomeScreenRoomCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.redactionReasons) private var redactionReasons
    
    let room: HomeScreenRoom
    let isSelected: Bool
    let mediaProvider: MediaProviderProtocol!
    let action: (HomeScreenViewAction) -> Void
    
    private let verticalInsets = 12.0
    private let horizontalInsets = 16.0
    
    var body: some View {
        Button {
            if let roomID = room.roomID {
                action(.selectRoom(roomIdentifier: roomID))
            }
        } label: {
            HStack(spacing: 16.0) {
                avatar
                
                content
                    .padding(.vertical, verticalInsets)
                    .overlay(alignment: .bottom) {
                        Rectangle()
                            .fill(Color.compound.borderDisabled)
                            .frame(height: 1 / UIScreen.main.scale)
                            .padding(.trailing, -horizontalInsets)
                    }
            }
            .padding(.horizontal, horizontalInsets)
            .accessibilityElement(children: .combine)
        }
        .buttonStyle(HomeScreenRoomCellButtonStyle(isSelected: isSelected))
        .accessibilityIdentifier(A11yIdentifiers.homeScreen.roomName(room.name))
        .accessibilityHidden(redactionReasons.contains(.placeholder) ? true : false)
    }
    
    @ViewBuilder @MainActor
    private var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: room.avatar,
                            avatarSize: .room(on: .chats),
                            mediaProvider: mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
    
    private var content: some View {
        VStack(alignment: .leading, spacing: 2) {
            header
            footer
        }
        // Hide the normal content for Skeletons and overlay centre aligned placeholders.
        .opacity(redactionReasons.contains(.placeholder) ? 0 : 1)
        .overlay {
            if redactionReasons.contains(.placeholder) {
                VStack(alignment: .leading, spacing: 2) {
                    header
                    lastMessage
                }
            }
        }
    }
    
    private var header: some View {
        HStack(alignment: .top, spacing: 16) {
            Text(room.name)
                .font(.compound.bodyLGSemibold)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            if let timestamp = room.timestamp {
                Text(timestamp)
                    .font(room.isHighlighted ? .compound.bodySMSemibold : .compound.bodySM)
                    .foregroundColor(room.isHighlighted ? .compound.textActionAccent : .compound.textSecondary)
            }
        }
    }
    
    private var footer: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Hidden text with 2 lines to maintain consistent height, scaling with dynamic text.
                Text(" \n ")
                    .lastMessageFormatting(hasFailed: false)
                    .hidden()
                    .environment(\.redactionReasons, []) // Always maintain consistent height
                
                HStack(alignment: .top, spacing: 4.0) {
                    switch room.lastMessageState {
                    case .sending:
                        CompoundIcon(\.time, size: .small, relativeTo: .compound.bodyMD)
                            .foregroundStyle(.compound.iconTertiary)
                            .offset(y: -1)
                            .accessibilityLabel(L10n.commonSending)
                    case .failed:
                        CompoundIcon(\.errorSolid, size: .small, relativeTo: .compound.bodyMD)
                            .foregroundStyle(.compound.iconCriticalPrimary)
                            .offset(y: -1)
                            .accessibilityHidden(true) // The last message contains the error.
                    case .none:
                        EmptyView()
                    }
                    
                    lastMessage
                }
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if room.badges.isCallShown {
                    CompoundIcon(\.videoCallSolid, size: .xSmall, relativeTo: .compound.bodySM)
                        .accessibilityLabel(L10n.a11yNotificationsOngoingCall)
                }
                
                if room.badges.isMuteShown {
                    CompoundIcon(\.notificationsOffSolid, size: .custom(15), relativeTo: .compound.bodyMD)
                        .accessibilityLabel(L10n.a11yNotificationsMuted)
                }
                
                if room.badges.isMentionShown {
                    mentionIcon
                }
                
                if room.badges.isDotShown {
                    Circle()
                        .frame(width: 12, height: 12)
                        .accessibilityLabel(L10n.a11yNotificationsNewMessages)
                }
            }
            .foregroundColor(room.isHighlighted ? .compound.iconAccentTertiary : .compound.iconQuaternary)
        }
    }
            
    private var mentionIcon: some View {
        CompoundIcon(\.mention, size: .custom(15), relativeTo: .compound.bodyMD)
            .accessibilityLabel(L10n.a11yNotificationsNewMentions)
    }
    
    @ViewBuilder
    private var lastMessage: some View {
        if let displayedLastMessage = room.displayedLastMessage {
            Text(displayedLastMessage)
                .lastMessageFormatting(hasFailed: room.lastMessageState == .failed)
        }
    }
}

struct HomeScreenRoomCellButtonStyle: ButtonStyle {
    let isSelected: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .background(isSelected ? Color.compound.bgSubtleSecondary : Color.compound.bgCanvasDefault)
            .contentShape(Rectangle())
            .animation(isSelected ? .none : .easeOut(duration: 0.1).disabledDuringTests(), value: isSelected)
    }
}

private extension View {
    func lastMessageFormatting(hasFailed: Bool) -> some View {
        font(.compound.bodyMD)
            .foregroundColor(hasFailed ? .compound.textCriticalPrimary : .compound.textSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
}

// MARK: - Previews

import MatrixRustSDKMocks

struct HomeScreenRoomCell_Previews: PreviewProvider, TestablePreview {
    static let summaryProviderGeneric = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
    static let genericRooms = summaryProviderGeneric.roomListPublisher.value.compactMap(mockRoom)
    
    static let summaryProviderForNotificationsState = RoomSummaryProviderMock(.init(state: .loaded(.mockRoomsWithNotificationsState)))
    static let notificationsStateRooms = summaryProviderForNotificationsState.roomListPublisher.value.compactMap(mockRoom)
    
    static let lastMessageStateRooms = [makeRoom(lastMessageState: .sending), makeRoom(lastMessageState: .failed)]
    
    static var previews: some View {
        VStack(spacing: 0) {
            ForEach(genericRooms) { room in
                HomeScreenRoomCell(room: room, isSelected: false, mediaProvider: MediaProviderMock(configuration: .init())) { _ in }
            }
            
            HomeScreenRoomCell(room: .placeholder(), isSelected: false, mediaProvider: MediaProviderMock(configuration: .init())) { _ in }
                .redacted(reason: .placeholder)
        }
        .previewDisplayName("Generic")
        
        VStack(spacing: 0) {
            ForEach(notificationsStateRooms) { room in
                HomeScreenRoomCell(room: room, isSelected: false, mediaProvider: MediaProviderMock(configuration: .init())) { _ in }
            }
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Notifications State")
        
        VStack(spacing: 0) {
            ForEach(lastMessageStateRooms) { room in
                HomeScreenRoomCell(room: room, isSelected: false, mediaProvider: MediaProviderMock(configuration: .init())) { _ in }
            }
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Last Message State")
    }
    
    static func mockRoom(summary: RoomSummary) -> HomeScreenRoom? {
        HomeScreenRoom(summary: summary, hideUnreadMessagesBadge: false)
    }
    
    static func makeViewModel(roomSummaryProvider: RoomSummaryProviderProtocol) -> HomeScreenViewModel {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "John Doe", roomSummaryProvider: roomSummaryProvider))))

        return HomeScreenViewModel(userSession: userSession,
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   appSettings: ServiceLocator.shared.settings,
                                   analyticsService: ServiceLocator.shared.analytics,
                                   notificationManager: NotificationManagerMock(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
    
    static func makeRoom(lastMessageState: RoomSummary.LastMessageState) -> HomeScreenRoom {
        let summary = RoomSummary(room: RoomSDKMock(),
                                  id: UUID().uuidString,
                                  joinRequestType: nil,
                                  name: "Foundation and Empire",
                                  isDirect: false,
                                  isSpace: false,
                                  avatarURL: .mockMXCAvatar,
                                  heroes: [],
                                  activeMembersCount: 0,
                                  lastMessage: AttributedString("How do you see the Emperor then? You think he keeps office hours?"),
                                  lastMessageDate: .mock,
                                  lastMessageState: lastMessageState,
                                  unreadMessagesCount: 2,
                                  unreadMentionsCount: 0,
                                  unreadNotificationsCount: 2,
                                  notificationMode: .mute,
                                  canonicalAlias: "#foundation-and-empire:matrix.org",
                                  alternativeAliases: [],
                                  hasOngoingCall: false,
                                  isMarkedUnread: false,
                                  isFavourite: false,
                                  isTombstoned: false)
        
        return .init(summary: summary, hideUnreadMessagesBadge: false)
    }
}
