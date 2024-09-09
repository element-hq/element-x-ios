//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct JoinRoomScreen: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @ObservedObject var context: JoinRoomScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: 80, background: .bloom) {
            if context.viewState.mode == .loading {
                EmptyView()
            } else {
                mainContent
            }
        } bottomContent: {
            buttons
        }
        .alert(item: $context.alertInfo)
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var mainContent: some View {
        VStack(spacing: 16) {
            RoomAvatarImage(avatar: context.viewState.avatar,
                            avatarSize: .room(on: .joinRoom),
                            mediaProvider: context.mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
            
            VStack(spacing: 8) {
                Text(context.viewState.title)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                
                if let subtitle = context.viewState.subtitle {
                    Text(subtitle)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                }
                
                if let memberCount = context.viewState.roomDetails?.memberCount {
                    BadgeLabel(title: "\(memberCount)", icon: \.userProfile, isHighlighted: false)
                }
                
                if let inviter = context.viewState.roomDetails?.inviter {
                    RoomInviterLabel(inviter: inviter, mediaProvider: context.mediaProvider)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                }
                
                if let topic = context.viewState.roomDetails?.topic {
                    Text(topic)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                        .lineLimit(3)
                }
            }
        }
    }
    
    @ViewBuilder
    var buttons: some View {
        switch context.viewState.mode {
        case .loading, .unknown:
            EmptyView()
        case .knock:
            Button(L10n.screenJoinRoomKnockAction) { context.send(viewAction: .knock) }
                .buttonStyle(.compound(.primary))
        case .join:
            Button(L10n.screenJoinRoomJoinAction) { context.send(viewAction: .join) }
                .buttonStyle(.compound(.super))
        case .invited:
            ViewThatFits {
                HStack(spacing: 8) { inviteButtons }
                VStack(spacing: 16) { inviteButtons }
            }
        }
    }
    
    @ViewBuilder
    var inviteButtons: some View {
        Button(L10n.actionDecline) { context.send(viewAction: .declineInvite) }
            .buttonStyle(.compound(.secondary))
        Button(L10n.actionAccept) { context.send(viewAction: .acceptInvite) }
            .buttonStyle(.compound(.primary))
    }
}

// MARK: - Previews

struct JoinRoomScreen_Previews: PreviewProvider, TestablePreview {
    static let unknownViewModel = makeViewModel(mode: .unknown)
    static let knockViewModel = makeViewModel(mode: .knock)
    static let joinViewModel = makeViewModel(mode: .join)
    static let inviteViewModel = makeViewModel(mode: .invited)
    
    static var previews: some View {
        NavigationStack {
            JoinRoomScreen(context: unknownViewModel.context)
        }
        .previewDisplayName("Unknown")
        .snapshotPreferences(delay: 0.25)
        
        NavigationStack {
            JoinRoomScreen(context: knockViewModel.context)
        }
        .previewDisplayName("Knock")
        .snapshotPreferences(delay: 0.25)
        
        NavigationStack {
            JoinRoomScreen(context: joinViewModel.context)
        }
        .previewDisplayName("Join")
        .snapshotPreferences(delay: 0.25)
        
        NavigationStack {
            JoinRoomScreen(context: inviteViewModel.context)
        }
        .previewDisplayName("Invite")
        .snapshotPreferences(delay: 0.25)
    }
    
    static func makeViewModel(mode: JoinRoomScreenInteractionMode) -> JoinRoomScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        
        // swiftlint:disable:next large_tuple
        let membership: (isJoined: Bool, isInvited: Bool, isPublic: Bool, canKnock: Bool) = switch mode {
        case .loading, .unknown:
            (false, false, false, false)
        case .invited:
            (false, true, false, false)
        case .join:
            (false, false, true, false)
        case .knock:
            (false, false, false, true)
        }
        
        if mode == .unknown {
            clientProxy.roomPreviewForIdentifierViaReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        } else {
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(.init(roomID: "1",
                                                                                name: "The Three-Body Problem - 三体",
                                                                                canonicalAlias: "#3🌞problem:matrix.org",
                                                                                // swiftlint:disable:next line_length
                                                                                topic: "“Science and technology were the only keys to opening the door to the future, and people approached science with the faith and sincerity of elementary school students.”",
                                                                                avatarURL: URL.homeDirectory,
                                                                                memberCount: UInt(100),
                                                                                isHistoryWorldReadable: false,
                                                                                isJoined: membership.isJoined,
                                                                                isInvited: membership.isInvited,
                                                                                isPublic: membership.isPublic,
                                                                                canKnock: membership.canKnock))
        }
        
        return JoinRoomScreenViewModel(roomID: "1",
                                       via: [],
                                       allowKnocking: true,
                                       clientProxy: clientProxy,
                                       mediaProvider: MockMediaProvider(),
                                       userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
