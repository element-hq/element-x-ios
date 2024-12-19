//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct JoinRoomScreen: View {
    private let maxKnockMessageLength = 500
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    @ObservedObject var context: JoinRoomScreenViewModel.Context
    @FocusState private var focus: Focus?
    
    private enum Focus {
        case knockMessage
    }

    var body: some View {
        FullscreenDialog(topPadding: context.viewState.mode == .knocked ? 151 : 35) {
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
        .toolbar { toolbar }
        .shouldScrollOnKeyboardDidShow(focus == .knockMessage, to: Focus.knockMessage)
    }
    
    @ViewBuilder
    var mainContent: some View {
        switch context.viewState.mode {
        case .knocked:
            knockedView
        default:
            defaultView
        }
    }
    
    @ViewBuilder
    private var defaultView: some View {
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
                        .font(.compound.bodyLG)
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
                
                if context.viewState.mode == .knock {
                    knockMessage
                        .padding(.top, 19)
                }
            }
        }
    }
    
    @ViewBuilder
    private var knockedView: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.checkCircleSolid, style: .successSolid)
            VStack(spacing: 8) {
                Text(L10n.screenJoinRoomKnockSentTitle)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                Text(L10n.screenJoinRoomKnockSentDescription)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
        }
    }
    
    private var knockMessageFooterString: String {
        guard !context.knockMessage.isEmpty else {
            return L10n.screenJoinRoomKnockMessageDescription
        }
        return "\(context.knockMessage.count)/\(maxKnockMessageLength)"
    }
        
    @ViewBuilder
    private var knockMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                TextField("", text: $context.knockMessage, axis: .vertical)
                    .focused($focus, equals: .knockMessage)
                    .onChange(of: context.knockMessage) { _, newValue in
                        context.knockMessage = String(newValue.prefix(maxKnockMessageLength))
                    }
                    .lineLimit(4, reservesSpace: true)
                    .font(.compound.bodyMD)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .id(Focus.knockMessage)
            }
            .background(.compound.bgCanvasDefault)
            .cornerRadius(8)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .inset(by: 0.5)
                    .stroke(.compound.borderInteractivePrimary)
            }
            
            Text(knockMessageFooterString)
                .font(.compound.bodySM)
                .foregroundStyle(.compound.textSecondary)
        }
    }
    
    @ViewBuilder
    var buttons: some View {
        switch context.viewState.mode {
        case .loading, .unknown:
            EmptyView()
        case .knock:
            Button(L10n.screenJoinRoomKnockAction) { context.send(viewAction: .knock) }
                .buttonStyle(.compound(.super))
        case .knocked:
            Button(L10n.screenJoinRoomCancelKnockAction) { context.send(viewAction: .cancelKnock) }
                .buttonStyle(.compound(.secondary))
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
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if context.viewState.mode == .knocked {
            ToolbarItem(placement: .principal) {
                RoomHeaderView(roomName: context.viewState.title,
                               roomAvatar: context.viewState.avatar,
                               mediaProvider: context.mediaProvider)
            }
        }
    }
}

// MARK: - Previews

struct JoinRoomScreen_Previews: PreviewProvider, TestablePreview {
    static let unknownViewModel = makeViewModel(mode: .unknown)
    static let knockViewModel = makeViewModel(mode: .knock)
    static let joinViewModel = makeViewModel(mode: .join)
    static let inviteViewModel = makeViewModel(mode: .invited)
    static let knockedViewModel = makeViewModel(mode: .knocked)
    
    static var previews: some View {
        NavigationStack {
            JoinRoomScreen(context: unknownViewModel.context)
        }
        .snapshotPreferences(expect: unknownViewModel.context.$viewState.map { state in
            state.roomDetails != nil
        })
        .previewDisplayName("Unknown")
        
        NavigationStack {
            JoinRoomScreen(context: knockViewModel.context)
        }
        .snapshotPreferences(expect: knockViewModel.context.$viewState.map { state in
            state.roomDetails != nil
        })
        .previewDisplayName("Knock")
        
        NavigationStack {
            JoinRoomScreen(context: joinViewModel.context)
        }
        .snapshotPreferences(expect: joinViewModel.context.$viewState.map { state in
            state.roomDetails != nil
        })
        .previewDisplayName("Join")
        
        NavigationStack {
            JoinRoomScreen(context: inviteViewModel.context)
        }
        .snapshotPreferences(expect: inviteViewModel.context.$viewState.map { state in
            state.roomDetails != nil
        })
        .previewDisplayName("Invite")
        
        NavigationStack {
            JoinRoomScreen(context: knockedViewModel.context)
        }
        .snapshotPreferences(expect: knockedViewModel.context.$viewState.map { state in
            state.roomDetails != nil
        })
        .previewDisplayName("Knocked")
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
        case .knocked:
            (false, false, false, false)
        }
        
        if mode == .unknown {
            clientProxy.roomPreviewForIdentifierViaReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        } else {
            switch mode {
            case .knocked:
                clientProxy.roomForIdentifierClosure = { _ in
                    .knocked(KnockedRoomProxyMock(.init(avatarURL: .mockMXCAvatar)))
                }
            case .invited:
                clientProxy.roomForIdentifierClosure = { _ in
                    .invited(InvitedRoomProxyMock(.init(avatarURL: .mockMXCAvatar)))
                }
            default:
                break
            }
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(.init(roomID: "1",
                                                                                name: "The Three-Body Problem - 三体",
                                                                                canonicalAlias: "#3🌞problem:matrix.org",
                                                                                // swiftlint:disable:next line_length
                                                                                topic: "“Science and technology were the only keys to opening the door to the future, and people approached science with the faith and sincerity of elementary school students.”",
                                                                                avatarURL: .mockMXCAvatar,
                                                                                memberCount: UInt(100),
                                                                                isHistoryWorldReadable: nil,
                                                                                isJoined: membership.isJoined,
                                                                                isInvited: membership.isInvited,
                                                                                isPublic: membership.isPublic,
                                                                                canKnock: membership.canKnock))
        }
        
        ServiceLocator.shared.settings.knockingEnabled = true
        
        return JoinRoomScreenViewModel(roomID: "1",
                                       via: [],
                                       appSettings: ServiceLocator.shared.settings,
                                       clientProxy: clientProxy,
                                       mediaProvider: MediaProviderMock(configuration: .init()),
                                       userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
