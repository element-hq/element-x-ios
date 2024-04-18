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
import SwiftUI

@MainActor
struct HomeScreenInviteCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let room: HomeScreenRoom
    let context: HomeScreenViewModel.Context
    
    var body: some View {
        Button {
            if let roomId = room.roomId {
                context.send(viewAction: .selectRoom(roomIdentifier: roomId))
            }
        } label: {
            HStack(alignment: .top, spacing: 16) {
                if dynamicTypeSize < .accessibility3 {
                    LoadableAvatarImage(url: room.avatarURL,
                                        name: title,
                                        contentID: room.id,
                                        avatarSize: .custom(52),
                                        imageProvider: context.imageProvider)
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
        }
    }
    
    // MARK: - Private

    private var mainContent: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                textualContent
                badge
            }
            
            inviterView
                .padding(.top, 6)
                .padding(.trailing, 16)
            
            buttons
                .padding(.top, 14)
                .padding(.trailing, 22)
        }
    }

    @ViewBuilder
    private var inviterView: some View {
        if let invitedText = attributedInviteText, let name = room.inviter?.displayName {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                LoadableAvatarImage(url: room.inviter?.avatarURL,
                                    name: name,
                                    contentID: name,
                                    avatarSize: .custom(16),
                                    imageProvider: context.imageProvider)
                    .alignmentGuide(.firstTextBaseline) { $0[.bottom] * 0.8 }
                
                Text(invitedText)
            }
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
            .accessibilityIdentifier(A11yIdentifiers.invitesScreen.decline)
            
            Button(L10n.actionAccept) {
                context.send(viewAction: .acceptInvite(roomIdentifier: room.id))
            }
            .buttonStyle(.compound(.primary, size: .medium))
            .accessibilityIdentifier(A11yIdentifiers.invitesScreen.accept)
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
        room.isDirect ? room.inviter?.userID : room.canonicalAlias
    }
    
    private var attributedInviteText: AttributedString? {
        guard
            room.isDirect == false,
            let inviterName = room.inviter?.displayName,
            let inviterID = room.inviter?.userID
        else {
            return nil
        }
        
        let text = L10n.screenInvitesInvitedYou(inviterName, inviterID)
        var attributedString = AttributedString(text)
        attributedString.font = .compound.bodyMD
        attributedString.foregroundColor = .compound.textPlaceholder
        if let range = attributedString.range(of: inviterName) {
            attributedString[range].foregroundColor = .compound.textPrimary
            attributedString[range].font = .compound.bodyMDSemibold
        }
        return attributedString
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
        
        let userSession = MockUserSession(clientProxy: clientProxy,
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
        
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
        
        let details = RoomSummaryDetails(id: "@someone:somewhere.com",
                                         isInvite: false,
                                         inviter: inviter,
                                         name: "Some Guy",
                                         isDirect: true,
                                         avatarURL: nil,
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
        
        return .init(details: details, invalidated: false, hideUnreadMessagesBadge: false)
    }
    
    static func roomInvite(alias: String? = nil, avatarURL: URL? = nil) -> HomeScreenRoom {
        let inviter = RoomMemberProxyMock()
        inviter.displayName = "Luca"
        inviter.userID = "@jack:somewhi.nl"
        inviter.avatarURL = avatarURL
        
        let details = RoomSummaryDetails(id: "@someone:somewhere.com",
                                         isInvite: false,
                                         inviter: inviter,
                                         name: "Awesome Room",
                                         isDirect: false,
                                         avatarURL: avatarURL,
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
        
        return .init(details: details, invalidated: false, hideUnreadMessagesBadge: false)
    }
}
