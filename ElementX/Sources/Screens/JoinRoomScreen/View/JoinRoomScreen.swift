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
    
    private var topPadding: CGFloat {
        if context.viewState.roomDetails?.inviter != nil {
            return 32
        }
        return context.viewState.mode == .knocked ? 151 : 44
    }

    var body: some View {
        FullscreenDialog(topPadding: topPadding) {
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
            if let inviter = context.viewState.roomDetails?.inviter {
                RoomInviterLabel(inviter: inviter,
                                 shouldHideAvatar: context.viewState.hideInviteAvatars,
                                 mediaProvider: context.mediaProvider)
                    .multilineTextAlignment(.center)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .padding(.bottom, 44)
            }
            
            if let avatar = context.viewState.avatar {
                RoomAvatarImage(avatar: avatar,
                                avatarSize: .room(on: .joinRoom),
                                mediaProvider: context.mediaProvider)
                    .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                    .accessibilityHidden(true)
            } else {
                RoomAvatarImage(avatar: .room(id: "", name: nil, avatarURL: nil),
                                avatarSize: .room(on: .joinRoom),
                                mediaProvider: context.mediaProvider)
                    .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                    .hidden()
                    .accessibilityHidden(true)
            }
            
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
                
                if !context.viewState.isDMInvite, let memberCount = context.viewState.roomDetails?.memberCount {
                    BadgeLabel(title: "\(memberCount)", icon: \.userProfile, style: .default)
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
        
    @ViewBuilder
    private var knockMessage: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 0) {
                TextField(L10n.screenJoinRoomKnockMessageDescription, text: $context.knockMessage, axis: .vertical)
                    .focused($focus, equals: .knockMessage)
                    .onChange(of: context.knockMessage) { _, newValue in
                        context.knockMessage = String(newValue.prefix(maxKnockMessageLength))
                    }
                    .lineLimit(4, reservesSpace: true)
                    .font(.compound.bodyMD)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .id(Focus.knockMessage)
                    .accessibilityHint(L10n.screenJoinRoomKnockMessageCharactersCount(context.knockMessage.count, maxKnockMessageLength))
            }
            .background(.compound.bgCanvasDefault)
            .cornerRadius(8)
            .overlay {
                RoundedRectangle(cornerRadius: 8)
                    .inset(by: 0.5)
                    .stroke(.compound.borderInteractivePrimary)
                    .accessibilityHidden(true)
            }
            
            Text("\(context.knockMessage.count)/\(maxKnockMessageLength)")
                .font(.compound.bodySM)
                .foregroundStyle(.compound.textSecondary)
                // We will have a hint for this in voice over mode
                .accessibilityHidden(true)
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
                VStack(spacing: 24) {
                    HStack(spacing: 16) {
                        inviteButtons
                    }
                    declineAndBlockButton
                }
                
                VStack(spacing: 16) {
                    inviteButtons
                    declineAndBlockButton
                }
            }
        case .banned(let sender, let reason):
            VStack(spacing: 24) {
                if let sender, let reason {
                    bottomErrorMessage(title: L10n.screenJoinRoomBanByMessage(sender),
                                       subtitle: L10n.screenJoinRoomBanReason(reason))
                } else {
                    bottomErrorMessage(title: L10n.screenJoinRoomBanMessage, subtitle: nil)
                }
                
                Button(L10n.screenJoinRoomForgetAction) {
                    context.send(viewAction: .forget)
                }
                .buttonStyle(.compound(.primary))
            }
        case .forbidden:
            forbiddenView
        }
    }
    
    private var forbiddenView: some View {
        VStack(spacing: 24) {
            bottomErrorMessage(title: L10n.screenJoinRoomFailMessage, subtitle: L10n.screenJoinRoomFailReason)
            Button(L10n.actionOk) {
                context.send(viewAction: .dismiss)
            }
            .buttonStyle(.compound(.primary))
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
            CompoundIcon(\.errorSolid)
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
    
    @ViewBuilder
    var declineAndBlockButton: some View {
        if let inviter = context.viewState.roomDetails?.inviter {
            Button(L10n.screenJoinRoomDeclineAndBlockButtonTitle, role: .destructive) {
                context.send(viewAction: .declineInviteAndBlock(userID: inviter.id))
            }
            .buttonStyle(.compound(.tertiary))
        }
    }
    
    var joinButton: some View {
        Button(L10n.screenJoinRoomJoinAction) { context.send(viewAction: .join) }
            .buttonStyle(.compound(.super))
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if context.viewState.mode == .knocked {
            ToolbarItem(placement: .principal) {
                if let avatar = context.viewState.avatar {
                    RoomHeaderView(roomName: context.viewState.title,
                                   roomAvatar: avatar,
                                   mediaProvider: context.mediaProvider)
                }
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
    static let invitedViewModel = makeViewModel(mode: .invited(isDM: false))
    static let invitedDMViewModel = makeViewModel(mode: .invited(isDM: true))
    static let invitedViewModelWithHiddenAvatars = makeViewModel(mode: .invited(isDM: false), hideInviteAvatars: true)
    static let invitedDMViewModelWithHiddenAvatars = makeViewModel(mode: .invited(isDM: true), hideInviteAvatars: true)
    static let knockableViewModel = makeViewModel(mode: .knockable)
    static let knockedViewModel = makeViewModel(mode: .knocked)
    static let bannedViewModel = makeViewModel(mode: .banned(sender: "Bob", reason: "Spamming"))
    static let forbiddenViewModel = makeViewModel(mode: .forbidden)
    
    static var previews: some View {
        makePreview(viewModel: unknownViewModel, mode: .unknown)
        makePreview(viewModel: joinableViewModel, mode: .joinable)
        makePreview(viewModel: restrictedViewModel, mode: .restricted)
        makePreview(viewModel: inviteRequiredViewModel, mode: .inviteRequired)
        makePreview(viewModel: invitedViewModel, mode: .invited(isDM: false))
        makePreview(viewModel: invitedDMViewModel, mode: .invited(isDM: true))
        makePreview(viewModel: invitedViewModelWithHiddenAvatars,
                    mode: .invited(isDM: false),
                    customPreviewName: "InvitedWithHiddenAvatars")
        makePreview(viewModel: knockableViewModel, mode: .knockable)
        makePreview(viewModel: knockedViewModel, mode: .knocked)
        makePreview(viewModel: bannedViewModel, mode: .banned(sender: nil, reason: nil))
        makePreview(viewModel: forbiddenViewModel, mode: .forbidden)
    }
    
    @ViewBuilder
    static func makePreview(viewModel: JoinRoomScreenViewModel,
                            mode: JoinRoomScreenMode,
                            customPreviewName: String? = nil) -> some View {
        if mode == .forbidden {
            NavigationStack {
                JoinRoomScreen(context: viewModel.context)
            }
            .snapshotPreferences(expect: viewModel.context.$viewState.map { state in
                state.mode == .forbidden
            })
            .onAppear {
                forbiddenViewModel.context.send(viewAction: .join)
            }
            .previewDisplayName(customPreviewName ?? mode.previewDisplayName)
        } else {
            NavigationStack {
                JoinRoomScreen(context: viewModel.context)
            }
            .snapshotPreferences(expect: viewModel.context.$viewState.map { state in
                state.roomDetails != nil
            })
            .previewDisplayName(customPreviewName ?? mode.previewDisplayName)
        }
    }
    
    static func makeViewModel(mode: JoinRoomScreenMode, hideInviteAvatars: Bool = false) -> JoinRoomScreenViewModel {
        let appSettings = AppSettings()
        appSettings.knockingEnabled = true
        
        let clientProxy = ClientProxyMock(.init(hideInviteAvatars: hideInviteAvatars))
        
        switch mode {
        case .unknown:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .failure(.roomPreviewIsPrivate)
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
        case .invited(let isDM):
            if isDM {
                clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.inviteDM())
                clientProxy.roomForIdentifierClosure = { _ in
                    .invited(InvitedRoomProxyMock(.init(avatarURL: .mockMXCAvatar)))
                }
            } else {
                clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.invited())
                clientProxy.roomForIdentifierClosure = { _ in
                    .invited(InvitedRoomProxyMock(.init(avatarURL: .mockMXCAvatar)))
                }
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
                .banned(BannedRoomProxyMock(.init(avatarURL: .mockMXCAvatar)))
            }
        case .forbidden:
            clientProxy.roomPreviewForIdentifierViaReturnValue = .success(RoomPreviewProxyMock.restricted)
            clientProxy.roomForIdentifierReturnValue = nil
            clientProxy.joinRoomAliasClosure = { _ in
                .failure(.forbiddenAccess)
            }
        default:
            break
        }
        
        return JoinRoomScreenViewModel(roomID: "1",
                                       via: [],
                                       appSettings: appSettings,
                                       clientProxy: clientProxy,
                                       mediaProvider: MediaProviderMock(configuration: .init()),
                                       userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}

private extension JoinRoomScreenMode {
    var previewDisplayName: String {
        switch self {
        case .unknown:
            return "Unknown"
        case .loading:
            return "Loading"
        case .joinable:
            return "Joinable"
        case .restricted:
            return "Restricted"
        case .inviteRequired:
            return "InviteRequired"
        case .invited(isDM: let isDM):
            return isDM ? "InvitedDM" : "Invited"
        case .knockable:
            return "Knockable"
        case .knocked:
            return "Knocked"
        case .banned:
            return "Banned"
        case .forbidden:
            return "Forbidden"
        }
    }
}
