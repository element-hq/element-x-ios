//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomMemberDetailsScreen: View {
    @ObservedObject var context: RoomMemberDetailsScreenViewModel.Context
    
    var body: some View {
        Form {
            headerSection
            
            if context.viewState.memberDetails != nil, !context.viewState.isOwnMemberDetails {
                blockUserSection
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenRoomMemberDetailsTitle)
        .alert(item: $context.ignoreUserAlert, actions: blockUserAlertActions, message: blockUserAlertMessage)
        .alert(item: $context.alertInfo)
        .track(screen: .User)
        .interactiveQuickLook(item: $context.mediaPreviewItem, allowEditing: false)
    }
    
    // MARK: - Private
    
    @ViewBuilder
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
        .padding(.top, 32)
    }
    
    @ViewBuilder
    private var headerSection: some View {
        if let memberDetails = context.viewState.memberDetails {
            AvatarHeaderView(member: memberDetails,
                             avatarSize: .user(on: .memberDetails),
                             mediaProvider: context.mediaProvider) {
                context.send(viewAction: .displayAvatar)
            } footer: {
                otherUserFooter
            }
        } else {
            AvatarHeaderView(user: UserProfileProxy(userID: context.viewState.userID),
                             avatarSize: .user(on: .memberDetails),
                             mediaProvider: context.mediaProvider,
                             footer: { })
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
    static let otherUserViewModel = makeViewModel(member: .mockDan)
    static let accountOwnerViewModel = makeViewModel(member: .mockMe)
    static let ignoredUserViewModel = makeViewModel(member: .mockIgnored)
    
    static var previews: some View {
        RoomMemberDetailsScreen(context: otherUserViewModel.context)
            .previewDisplayName("Other User")
            .snapshotPreferences(delay: 0.25)
        RoomMemberDetailsScreen(context: accountOwnerViewModel.context)
            .previewDisplayName("Account Owner")
            .snapshotPreferences(delay: 0.25)
        RoomMemberDetailsScreen(context: ignoredUserViewModel.context)
            .previewDisplayName("Ignored User")
            .snapshotPreferences(delay: 0.25)
    }
    
    static func makeViewModel(member: RoomMemberProxyMock) -> RoomMemberDetailsScreenViewModel {
        let roomProxyMock = JoinedRoomProxyMock(.init(name: ""))
        roomProxyMock.getMemberUserIDReturnValue = .success(member)
        
        let clientProxyMock = ClientProxyMock(.init())
        
        // to avoid mock the call state for the account owner test case
        if member.userID != RoomMemberProxyMock.mockMe.userID {
            clientProxyMock.directRoomForUserIDReturnValue = .success("roomID")
        }
        
        return RoomMemberDetailsScreenViewModel(userID: member.userID,
                                                roomProxy: roomProxyMock,
                                                clientProxy: clientProxyMock,
                                                mediaProvider: MockMediaProvider(),
                                                userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                analytics: ServiceLocator.shared.analytics)
    }
}
