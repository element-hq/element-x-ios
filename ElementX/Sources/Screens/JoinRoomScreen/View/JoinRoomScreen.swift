//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
            bottomContent
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
                
                if context.viewState.mode == .knockable {
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
    var bottomContent: some View {
        switch context.viewState.mode {
        case .loading:
            EmptyView()
        case .joinable:
            joinButton
        case .unknown, .restricted: // If unknown, do our best.
            VStack(spacing: 24) {
                bottomNoticeMessage(L10n.screenJoinRoomJoinRestrictedMessage)
                
                joinButton
            }
        case .knockable:
            Button(L10n.screenJoinRoomKnockAction) { context.send(viewAction: .knock) }
                .buttonStyle(.compound(.super))
        case .knocked:
            Button(L10n.screenJoinRoomCancelKnockAction) { context.send(viewAction: .cancelKnock) }
                .buttonStyle(.compound(.secondary))
        case .inviteRequired:
            bottomNoticeMessage(L10n.screenJoinRoomInviteRequiredMessage)
        case .invited:
            ViewThatFits {
                HStack(spacing: 8) { inviteButtons }
                VStack(spacing: 16) { inviteButtons }
            }
        case .banned(let sender, let reason):
            if let sender, let reason {
                bottomErrorMessage(title: L10n.screenJoinRoomBanByMessage(sender),
                                   subtitle: L10n.screenJoinRoomBanReason(reason))
            } else {
                bottomErrorMessage(title: L10n.screenJoinRoomBanMessage, subtitle: nil)
            }
        }
    }
    
    func bottomNoticeMessage(_ notice: String) -> some View {
        Label(notice, icon: \.info)
            .labelStyle(.custom(spacing: 12, alignment: .top))
            .font(.compound.bodyLGSemibold)
            .foregroundStyle(.compound.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(.compound.bgSubtleSecondary)
            .cornerRadius(14, corners: .allCorners)
    }
    
    func bottomErrorMessage(title: String, subtitle: String?) -> some View {
        Label {
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.compound.bodyLGSemibold)
                    .foregroundStyle(.compound.textCriticalPrimary)
                
                if let subtitle {
                    Text(subtitle)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                }
            }
        } icon: {
            CompoundIcon(\.error)
                .foregroundStyle(.compound.iconCriticalPrimary)
        }
        .labelStyle(.custom(spacing: 12, alignment: .top))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(.compound.bgSubtleSecondary)
        .cornerRadius(14, corners: .allCorners)
    }
    
    @ViewBuilder
    var inviteButtons: some View {
        Button(L10n.actionDecline) { context.send(viewAction: .declineInvite) }
            .buttonStyle(.compound(.secondary))
        Button(L10n.actionAccept) { context.send(viewAction: .acceptInvite) }
            .buttonStyle(.compound(.primary))
    }
    
    var joinButton: some View {
        Button(L10n.screenJoinRoomJoinAction) { context.send(viewAction: .join) }
            .buttonStyle(.compound(.super))
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
    static let joinableViewModel = makeViewModel(mode: .joinable)
    static let restrictedViewModel = makeViewModel(mode: .restricted)
    static let inviteRequiredViewModel = makeViewModel(mode: .inviteRequired)
    static let invitedViewModel = makeViewModel(mode: .invited)
    static let knockableViewModel = makeViewModel(mode: .knockable)
    static let knockedViewModel = makeViewModel(mode: .knocked)
    static let bannedViewModel = makeViewModel(mode: .banned(sender: "Bob", reason: "Spamming"))
    
    static var previews: some View {
        makePreview(viewModel: unknownViewModel, previewDisplayName: "Unknown")
        makePreview(viewModel: joinableViewModel, previewDisplayName: "Joinable")
        makePreview(viewModel: restrictedViewModel, previewDisplayName: "Restricted")
        makePreview(viewModel: inviteRequiredViewModel, previewDisplayName: "InviteRequired")
        makePreview(viewModel: invitedViewModel, previewDisplayName: "Invited")
        makePreview(viewModel: knockableViewModel, previewDisplayName: "Knockable")
        makePreview(viewModel: knockedViewModel, previewDisplayName: "Knocked")
        makePreview(viewModel: bannedViewModel, previewDisplayName: "Banned")
    }
    
    static func makePreview(viewModel: JoinRoomScreenViewModel, previewDisplayName: String) -> some View {
        NavigationStack {
            JoinRoomScreen(context: viewModel.context)
        }
        .snapshotPreferences(expect: viewModel.context.$viewState.map { state in
            state.roomDetails != nil
        })
        .previewDisplayName(previewDisplayName)
    }
    
    static func makeViewModel(mode: JoinRoomScreenMode) -> JoinRoomScreenViewModel {
        ServiceLocator.shared.settings.knockingEnabled = true
        
        let clientProxy = ClientProxyMock(.init())
        
        switch mode {
        case .unknown:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
            clientProxy.roomForIdentifierReturnValue = nil
        case .joinable:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.joinable)
            clientProxy.roomForIdentifierReturnValue = nil
        case .restricted:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.restricted)
            clientProxy.roomForIdentifierReturnValue = nil
        case .inviteRequired:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.inviteRequired)
            clientProxy.roomForIdentifierReturnValue = nil
        case .invited:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.invited())
            clientProxy.roomForIdentifierClosure = { _ in
                .invited(InvitedRoomProxyMock(.init(avatarURL: .mockMXCAvatar)))
            }
        case .knockable:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.knockable)
            clientProxy.roomForIdentifierReturnValue = nil
        case .knocked:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.knocked)
            clientProxy.roomForIdentifierClosure = { _ in
                .knocked(KnockedRoomProxyMock(.init(avatarURL: .mockMXCAvatar)))
            }
        case .banned:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.banned)
            clientProxy.roomForIdentifierClosure = { _ in
                .banned
            }
        default:
            break
        }
        
        return JoinRoomScreenViewModel(roomID: "1",
                                       via: [],
                                       appSettings: ServiceLocator.shared.settings,
                                       clientProxy: clientProxy,
                                       mediaProvider: MediaProviderMock(configuration: .init()),
                                       userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
