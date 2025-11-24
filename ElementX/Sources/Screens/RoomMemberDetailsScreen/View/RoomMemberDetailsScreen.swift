//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomMemberDetailsScreen: View {
    @ObservedObject var context: RoomMemberDetailsScreenViewModel.Context
    
    var body: some View {
        Form {
            headerSection
            
            if context.viewState.showVerifyIdentitySection {
                verificationSection
            }
            
            if context.viewState.memberDetails != nil, !context.viewState.isOwnMemberDetails {
                blockUserSection
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenRoomMemberDetailsTitle)
        .alert(item: $context.ignoreUserAlert, actions: blockUserAlertActions, message: blockUserAlertMessage)
        .alert(item: $context.alertInfo)
        .sheet(item: $context.inviteConfirmationUser) { user in
            SendInviteConfirmationView(userToInvite: user,
                                       mediaProvider: context.mediaProvider) {
                context.send(viewAction: .createDirectChat)
            }
        }
        .track(screen: .User)
        .interactiveQuickLook(item: $context.mediaPreviewItem, allowEditing: false)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var headerSection: some View {
        if let memberDetails = context.viewState.memberDetails {
            AvatarHeaderView(member: memberDetails,
                             isVerified: context.viewState.showVerifiedBadge,
                             avatarSize: .user(on: .memberDetails),
                             mediaProvider: context.mediaProvider) { url in
                context.send(viewAction: .displayAvatar(url))
            } footer: {
                VStack(spacing: 24) {
                    if context.viewState.showWithdrawVerificationSection {
                        withdrawVerificationSection
                    }
                    
                    otherUserFooter
                }
                .padding(.top, 24)
            }
        } else {
            AvatarHeaderView(user: UserProfileProxy(userID: context.viewState.userID),
                             isVerified: context.viewState.showVerifiedBadge,
                             avatarSize: .user(on: .memberDetails),
                             mediaProvider: context.mediaProvider) { }
        }
    }
    
    private var withdrawVerificationSection: some View {
        VStack(spacing: 16) {
            if let memberDetails = context.viewState.memberDetails {
                Text(L10n.cryptoIdentityChangeProfilePinViolation(memberDetails.name ?? memberDetails.id))
                    .foregroundStyle(.compound.textCriticalPrimary)
                    .font(.compound.bodyMDSemibold)
            } else {
                Text(L10n.cryptoIdentityChangeProfilePinViolation(context.viewState.userID))
                    .foregroundStyle(.compound.textCriticalPrimary)
                    .font(.compound.bodyMDSemibold)
            }
            
            Button {
                context.send(viewAction: .withdrawVerification)
            } label: {
                Text(L10n.cryptoIdentityChangeWithdrawVerificationAction)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compound(.secondary, size: .medium))
        }
        .padding(.horizontal, 16)
    }
    
    private var otherUserFooter: some View {
        HStack(spacing: 8) {
            if context.viewState.memberDetails != nil, !context.viewState.isOwnMemberDetails {
                Button {
                    context.send(viewAction: .openDirectChat)
                } label: {
                    CompoundIcon(\.chat)
                }
                .buttonStyle(FormActionButtonStyle(title: L10n.commonMessage))
                .accessibilityIdentifier(A11yIdentifiers.roomMemberDetailsScreen.directChat)
            }
            
            if let roomID = context.viewState.dmRoomID {
                Button {
                    context.send(viewAction: .startCall(roomID: roomID))
                } label: {
                    CompoundIcon(\.videoCall)
                }
                .buttonStyle(FormActionButtonStyle(title: L10n.actionCall))
            }
            
            if let permalink = context.viewState.memberDetails?.permalink {
                ShareLink(item: permalink) {
                    CompoundIcon(\.shareIos)
                }
                .buttonStyle(FormActionButtonStyle(title: L10n.actionShare))
            }
        }
    }
    
    var verificationSection: some View {
        Section {
            ListRow(label: .default(title: L10n.commonVerifyUser, icon: \.lock), kind: .button {
                context.send(viewAction: .verifyUser)
            })
        }
    }
    
    @ViewBuilder
    private var blockUserSection: some View {
        if let memberDetails = context.viewState.memberDetails {
            let title = memberDetails.isIgnored ? L10n.screenRoomMemberDetailsUnblockUser : L10n.screenRoomMemberDetailsBlockUser
            let action: RoomMemberDetailsScreenViewAction = memberDetails.isIgnored ? .showUnignoreAlert : .showIgnoreAlert
            let accessibilityIdentifier = memberDetails.isIgnored ? A11yIdentifiers.roomMemberDetailsScreen.unignore : A11yIdentifiers.roomMemberDetailsScreen.ignore
            
            Section {
                ListRow(label: .default(title: title,
                                        icon: \.block,
                                        role: memberDetails.isIgnored ? nil : .destructive),
                        details: .isWaiting(context.viewState.isProcessingIgnoreRequest),
                        kind: .button {
                            context.send(viewAction: action)
                        })
                        .accessibilityIdentifier(accessibilityIdentifier)
                        .disabled(context.viewState.isProcessingIgnoreRequest)
            }
        }
    }

    @ViewBuilder
    private func blockUserAlertActions(_ item: RoomMemberDetailsScreenViewStateBindings.IgnoreUserAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle,
               role: item.action == .ignore ? .destructive : nil) {
            context.send(viewAction: item.viewAction)
        }
    }

    private func blockUserAlertMessage(_ item: RoomMemberDetailsScreenViewStateBindings.IgnoreUserAlertItem) -> some View {
        Text(item.description)
    }
}

// MARK: - Previews

struct RoomMemberDetailsScreen_Previews: PreviewProvider, TestablePreview {
    static let verifiedUserViewModel = makeViewModel(member: .mockDan)
    static let verificationViolationUserViewModel = makeViewModel(member: .mockBob)
    static let otherUserViewModel = makeViewModel(member: .mockAlice)
    static let accountOwnerViewModel = makeViewModel(member: .mockMe)
    static let ignoredUserViewModel = makeViewModel(member: .mockIgnored)
    
    static var previews: some View {
        RoomMemberDetailsScreen(context: verifiedUserViewModel.context)
            .snapshotPreferences(expect: verifiedUserViewModel.context.$viewState.map { state in
                state.verificationState == .verified
            })
            .previewDisplayName("Verified User")
        
        RoomMemberDetailsScreen(context: verificationViolationUserViewModel.context)
            .snapshotPreferences(expect: verificationViolationUserViewModel.context.$viewState.map { state in
                state.verificationState == .verificationViolation
            })
            .previewDisplayName("Verification Violation User")
            
        RoomMemberDetailsScreen(context: otherUserViewModel.context)
            .snapshotPreferences(expect: otherUserViewModel.context.$viewState.map { state in
                state.memberDetails?.role == .user && state.dmRoomID != nil
            })
            .previewDisplayName("Other User")
            
        RoomMemberDetailsScreen(context: accountOwnerViewModel.context)
            .snapshotPreferences(expect: accountOwnerViewModel.context.$viewState.map { state in
                state.isOwnMemberDetails == true
            })
            .previewDisplayName("Account Owner")
            
        RoomMemberDetailsScreen(context: ignoredUserViewModel.context)
            .snapshotPreferences(expect: ignoredUserViewModel.context.$viewState.map { state in
                state.memberDetails?.isIgnored ?? false && state.dmRoomID != nil
            })
            .previewDisplayName("Ignored User")
    }
    
    static func makeViewModel(member: RoomMemberProxyMock) -> RoomMemberDetailsScreenViewModel {
        let roomProxyMock = JoinedRoomProxyMock(.init(name: ""))
        roomProxyMock.getMemberUserIDReturnValue = .success(member)
        
        let clientProxyMock = ClientProxyMock(.init())
        
        clientProxyMock.userIdentityForFallBackToServerClosure = { userID, _ in
            let identity = switch userID {
            case RoomMemberProxyMock.mockDan.userID:
                UserIdentityProxyMock(configuration: .init(verificationState: .verified))
            case RoomMemberProxyMock.mockBob.userID:
                UserIdentityProxyMock(configuration: .init(verificationState: .verificationViolation))
            default:
                UserIdentityProxyMock(configuration: .init())
            }
            
            return .success(identity)
        }
        
        // to avoid mock the call state for the account owner test case
        if member.userID != RoomMemberProxyMock.mockMe.userID {
            clientProxyMock.directRoomForUserIDReturnValue = .success("roomID")
        }
        
        return RoomMemberDetailsScreenViewModel(userID: member.userID,
                                                roomProxy: roomProxyMock,
                                                userSession: UserSessionMock(.init(clientProxy: clientProxyMock)),
                                                userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                analytics: ServiceLocator.shared.analytics)
    }
}
