//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct HomeScreenRoomCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.redactionReasons) private var redactionReasons
    
    let room: HomeScreenRoom
    let context: HomeScreenViewModel.Context
    let isSelected: Bool
    
    private let verticalInsets = 12.0
    private let horizontalInsets = 16.0
    
    var body: some View {
        Button {
            if let roomID = room.roomID {
                context.send(viewAction: .selectRoom(roomIdentifier: roomID))
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
    }
    
    @ViewBuilder @MainActor
    private var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: room.avatar,
                            avatarSize: .room(on: .home),
                            mediaProvider: context.mediaProvider)
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
    
    @ViewBuilder
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
    
    @ViewBuilder
    private var footer: some View {
        HStack(alignment: .firstTextBaseline, spacing: 0) {
            ZStack(alignment: .topLeading) {
                // Hidden text with 2 lines to maintain consistent height, scaling with dynamic text.
                Text(" \n ")
                    .lastMessageFormatting()
                    .hidden()
                    .environment(\.redactionReasons, []) // Always maintain consistent height
                
                lastMessage
            }
            
            Spacer()
            
            HStack(spacing: 8) {
                if room.badges.isCallShown {
                    CompoundIcon(\.videoCallSolid, size: .xSmall, relativeTo: .compound.bodySM)
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
                }
            }
            .foregroundColor(room.isHighlighted ? .compound.iconAccentTertiary : .compound.iconQuaternary)
        }
    }
            
    private var mentionIcon: some View {
        CompoundIcon(\.mention, size: .custom(15), relativeTo: .compound.bodyMD)
            .accessibilityLabel(L10n.a11yNotificationsMentionsOnly)
    }
    
    @ViewBuilder
    private var lastMessage: some View {
        if let lastMessage = room.lastMessage {
            Text(lastMessage)
                .lastMessageFormatting()
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
    func lastMessageFormatting() -> some View {
        font(.compound.bodyMD)
            .foregroundColor(.compound.textSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
    }
}

struct HomeScreenRoomCell_Previews: PreviewProvider, TestablePreview {
    static let summaryProviderGeneric = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
    static let viewModelGeneric = {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "John Doe", roomSummaryProvider: summaryProviderGeneric))))
        
        return HomeScreenViewModel(userSession: userSession,
                                   analyticsService: ServiceLocator.shared.analytics,
                                   appSettings: ServiceLocator.shared.settings,
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }()
    
    static let summaryProviderForNotificationsState = RoomSummaryProviderMock(.init(state: .loaded(.mockRoomsWithNotificationsState)))
    static let viewModelForNotificationsState = {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "John Doe", roomSummaryProvider: summaryProviderForNotificationsState))))

        return HomeScreenViewModel(userSession: userSession,
                                   analyticsService: ServiceLocator.shared.analytics,
                                   appSettings: ServiceLocator.shared.settings,
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }()
    
    static func mockRoom(summary: RoomSummary) -> HomeScreenRoom? {
        HomeScreenRoom(summary: summary, hideUnreadMessagesBadge: false)
    }
    
    static var previews: some View {
        let genericRooms: [HomeScreenRoom] = summaryProviderGeneric.roomListPublisher.value.compactMap(mockRoom)
        
        let notificationsStateRooms: [HomeScreenRoom] = summaryProviderForNotificationsState.roomListPublisher.value.compactMap(mockRoom)

        VStack(spacing: 0) {
            ForEach(genericRooms) { room in
                HomeScreenRoomCell(room: room, context: viewModelGeneric.context, isSelected: false)
            }
            
            HomeScreenRoomCell(room: .placeholder(), context: viewModelGeneric.context, isSelected: false)
                .redacted(reason: .placeholder)
        }
        .previewDisplayName("Generic")
        
        VStack(spacing: 0) {
            ForEach(notificationsStateRooms) { room in
                HomeScreenRoomCell(room: room, context: viewModelForNotificationsState.context, isSelected: false)
            }
        }
        .previewLayout(.sizeThatFits)
        .previewDisplayName("Notifications State")
    }
}
