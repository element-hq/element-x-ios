//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

@MainActor
struct HomeScreenInviteCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let room: HomeScreenRoom
    let context: HomeScreenViewModel.Context
    
    var body: some View {
        HStack(alignment: .top, spacing: 16) {
            if dynamicTypeSize < .accessibility3 {
                RoomAvatarImage(avatar: room.avatar,
                                avatarSize: .custom(52),
                                mediaProvider: context.mediaProvider)
                    .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                    .accessibilityHidden(true)
            }
            
            mainContent
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.bottom, 16)
                .padding(.trailing, 16)
                .multilineTextAlignment(.leading)
                .overlay(alignment: .bottom) {
                    separator
                }
        }
        .padding(.top, 12)
        .padding(.leading, 16)
        .onTapGesture {
            if let roomID = room.roomID {
                context.send(viewAction: .selectRoom(roomIdentifier: roomID))
            }
        }
    }
    
    // MARK: - Private

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .firstTextBaseline, spacing: 16) {
                    textualContent
                    badge
                }
                
                inviterView
                    .padding(.top, 6)
                    .padding(.trailing, 16)
            }
            .fixedSize(horizontal: false, vertical: true)
            .accessibilityElement(children: .combine)
            
            buttons
                .padding(.top, 14)
                .padding(.trailing, 22)
        }
    }

    @ViewBuilder
    private var inviterView: some View {
        if let inviter = room.inviter, !room.isDirect {
            RoomInviterLabel(inviter: inviter, mediaProvider: context.mediaProvider)
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textPlaceholder)
        }
    }
    
    @ViewBuilder
    private var textualContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title)
                .font(.compound.bodyLGSemibold)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(2)
            
            if let subtitle {
                Text(subtitle)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textPlaceholder)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    
    private var buttons: some View {
        HStack(spacing: 12) {
            Button(L10n.actionDecline) {
                context.send(viewAction: .declineInvite(roomIdentifier: room.id))
            }
            .buttonStyle(.compound(.secondary, size: .medium))
            
            Button(L10n.actionAccept) {
                context.send(viewAction: .acceptInvite(roomIdentifier: room.id))
            }
            .buttonStyle(.compound(.primary, size: .medium))
        }
    }
    
    private var separator: some View {
        Rectangle()
            .fill(Color.compound.borderDisabled)
            .frame(height: 1 / UIScreen.main.scale)
    }
        
    private var title: String {
        room.name
    }
    
    private var subtitle: String? {
        room.isDirect ? room.inviter?.id : room.canonicalAlias
    }
    
    private var badge: some View {
        Circle()
            .scaledFrame(size: 12)
            .foregroundColor(.compound.iconAccentTertiary)
    }
}

struct HomeScreenInviteCell_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        ScrollView {
            VStack(spacing: 0) {
                HomeScreenInviteCell(room: .dmInvite,
                                     context: viewModel().context)
                
                HomeScreenInviteCell(room: .dmInvite,
                                     context: viewModel().context)
                
                HomeScreenInviteCell(room: .roomInvite(),
                                     context: viewModel().context)
                
                HomeScreenInviteCell(room: .roomInvite(),
                                     context: viewModel().context)
                
                HomeScreenInviteCell(room: .roomInvite(alias: "#footest:somewhere.org", avatarURL: .picturesDirectory),
                                     context: viewModel().context)
                
                HomeScreenInviteCell(room: .roomInvite(alias: "#footest:somewhere.org"),
                                     context: viewModel().context)
                    .dynamicTypeSize(.accessibility1)
                    .previewDisplayName("Aliased room (AX1)")
            }
        }
    }
    
    static func viewModel() -> HomeScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        return HomeScreenViewModel(userSession: userSession,
                                   analyticsService: ServiceLocator.shared.analytics,
                                   appSettings: ServiceLocator.shared.settings,
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}

@MainActor
private extension HomeScreenRoom {
    static var dmInvite: HomeScreenRoom {
        let inviter = RoomMemberProxyMock()
        inviter.displayName = "Jack"
        inviter.userID = "@jack:somewhere.com"
        
        let summary = RoomSummary(roomListItem: RoomListItemSDKMock(),
                                  id: "@someone:somewhere.com",
                                  isInvite: false,
                                  inviter: inviter,
                                  name: "Some Guy",
                                  isDirect: true,
                                  avatarURL: nil,
                                  heroes: [.init(userID: "@someone:somewhere.com")],
                                  lastMessage: nil,
                                  lastMessageFormattedTimestamp: nil,
                                  unreadMessagesCount: 0,
                                  unreadMentionsCount: 0,
                                  unreadNotificationsCount: 0,
                                  notificationMode: nil,
                                  canonicalAlias: "#footest:somewhere.org",
                                  hasOngoingCall: false,
                                  isMarkedUnread: false,
                                  isFavourite: false)
        
        return .init(summary: summary, hideUnreadMessagesBadge: false)
    }
    
    static func roomInvite(alias: String? = nil, avatarURL: URL? = nil) -> HomeScreenRoom {
        let inviter = RoomMemberProxyMock()
        inviter.displayName = "Luca"
        inviter.userID = "@jack:somewhi.nl"
        inviter.avatarURL = avatarURL
        
        let summary = RoomSummary(roomListItem: RoomListItemSDKMock(),
                                  id: "@someone:somewhere.com",
                                  isInvite: false,
                                  inviter: inviter,
                                  name: "Awesome Room",
                                  isDirect: false,
                                  avatarURL: avatarURL,
                                  heroes: [.init(userID: "@someone:somewhere.com")],
                                  lastMessage: nil,
                                  lastMessageFormattedTimestamp: nil,
                                  unreadMessagesCount: 0,
                                  unreadMentionsCount: 0,
                                  unreadNotificationsCount: 0,
                                  notificationMode: nil,
                                  canonicalAlias: alias,
                                  hasOngoingCall: false,
                                  isMarkedUnread: false,
                                  isFavourite: false)
        
        return .init(summary: summary, hideUnreadMessagesBadge: false)
    }
}
