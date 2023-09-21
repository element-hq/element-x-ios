//
// Copyright 2022 New Vector Ltd
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
            if let roomId = room.roomId {
                context.send(viewAction: .selectRoom(roomIdentifier: roomId))
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
            LoadableAvatarImage(url: room.avatarURL,
                                name: room.name,
                                contentID: room.roomId,
                                avatarSize: .room(on: .home),
                                imageProvider: context.imageProvider)
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
                    .font(room.hasUnreads ? .compound.bodySMSemibold : .compound.bodySM)
                    .foregroundColor(room.hasUnreads ? .compound.textActionAccent : .compound.textSecondary)
            }
        }
    }
    
    @ViewBuilder
    private var footer: some View {
        HStack(alignment: .firstTextBaseline) {
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
                notificationModeIcon
                    .foregroundColor(room.hasUnreads ? .compound.iconAccentTertiary : .compound.iconQuaternary)
                
                if room.hasUnreads {
                    Circle()
                        .frame(width: 12, height: 12)
                        .foregroundColor(.compound.iconAccentTertiary)
                }
                
                if !room.hasDecoration {
                    // Force extra padding between last message text and the right border of the screen if there is no unread dot
                    Circle()
                        .frame(width: 12, height: 12)
                        .hidden()
                }
            }
            .padding(.leading, room.hasDecoration ? 12 : 0)
        }
    }
    
    @ViewBuilder
    private var notificationModeIcon: some View {
        switch room.notificationMode {
        case .none, .allMessages:
            EmptyView()
        case .mentionsAndKeywordsOnly:
            CompoundIcon(\.mention, size: .custom(15), relativeTo: .compound.bodyMD)
                .accessibilityLabel(L10n.a11yNotificationsMentionsOnly)
        case .mute:
            CompoundIcon(\.notificationsSolidOff, size: .custom(15), relativeTo: .compound.bodyMD)
                .accessibilityLabel(L10n.a11yNotificationsMuted)
        }
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
    static var previews: some View {
        let summaryProvider = MockRoomSummaryProvider(state: .loaded(.mockRooms))

        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "John Doe", roomSummaryProvider: summaryProvider),
                                          mediaProvider: MockMediaProvider())

        let viewModel = HomeScreenViewModel(userSession: userSession,
                                            attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL),
                                            selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                            appSettings: ServiceLocator.shared.settings,
                                            analytics: ServiceLocator.shared.analytics,
                                            userIndicatorController: ServiceLocator.shared.userIndicatorController)
        
        let rooms: [HomeScreenRoom] = summaryProvider.roomListPublisher.value.compactMap { summary -> HomeScreenRoom? in
            switch summary {
            case .empty:
                return nil
            case .invalidated(let details), .filled(let details):
                return HomeScreenRoom(id: UUID().uuidString,
                                      roomId: details.id,
                                      name: details.name,
                                      hasUnreads: details.unreadNotificationCount > 0,
                                      timestamp: Date(timeIntervalSinceReferenceDate: 0).formattedMinimal(),
                                      lastMessage: details.lastMessage,
                                      notificationMode: details.notificationMode)
            }
        }

        return VStack(spacing: 0) {
            ForEach(rooms) { room in
                HomeScreenRoomCell(room: room, context: viewModel.context, isSelected: false)
            }
            
            HomeScreenRoomCell(room: .placeholder(), context: viewModel.context, isSelected: false)
                .redacted(reason: .placeholder)
            HomeScreenRoomCell(room: .placeholder(), context: viewModel.context, isSelected: false)
                .redacted(reason: .placeholder)
            HomeScreenRoomCell(room: .placeholder(), context: viewModel.context, isSelected: false)
                .redacted(reason: .placeholder)
        }
    }
}
