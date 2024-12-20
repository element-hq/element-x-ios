//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct UserProfileScreen: View {
    @ObservedObject var context: UserProfileScreenViewModel.Context
    
    var body: some View {
        Form {
            headerSection
            
            verificationSection
        }
        .compoundList()
        .navigationTitle(L10n.screenRoomMemberDetailsTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
        .track(screen: .User)
        .interactiveQuickLook(item: $context.mediaPreviewItem, allowEditing: false)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var headerSection: some View {
        if let userProfile = context.viewState.userProfile {
            AvatarHeaderView(user: userProfile,
                             isVerified: context.viewState.showVerifiedBadge,
                             avatarSize: .user(on: .memberDetails),
                             mediaProvider: context.mediaProvider) { url in
                context.send(viewAction: .displayAvatar(url))
            } footer: {
                otherUserFooter
            }
        } else {
            AvatarHeaderView(user: UserProfileProxy(userID: context.viewState.userID),
                             isVerified: context.viewState.showVerifiedBadge,
                             avatarSize: .user(on: .memberDetails),
                             mediaProvider: context.mediaProvider) { }
        }
    }
    
    private var otherUserFooter: some View {
        HStack(spacing: 8) {
            if context.viewState.userProfile != nil, !context.viewState.isOwnUser {
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
            
            if let permalink = context.viewState.permalink {
                ShareLink(item: permalink) {
                    CompoundIcon(\.shareIos)
                }
                .buttonStyle(FormActionButtonStyle(title: L10n.actionShare))
            }
        }
        .padding(.top, 32)
    }
    
    @ViewBuilder
    var verificationSection: some View {
        if context.viewState.showVerificationSection {
            Section {
                ListRow(label: .default(title: L10n.commonVerifyIdentity,
                                        description: L10n.screenRoomMemberDetailsVerifyButtonSubtitle,
                                        icon: \.lock),
                        kind: .button { })
                    .disabled(true)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if context.viewState.isPresentedModally {
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.actionDone) {
                    context.send(viewAction: .dismiss)
                }
            }
        }
    }
}

// MARK: - Previews

struct UserProfileScreen_Previews: PreviewProvider, TestablePreview {
    static let verifiedUserViewModel = makeViewModel(userID: RoomMemberProxyMock.mockDan.userID)
    static let otherUserViewModel = makeViewModel(userID: RoomMemberProxyMock.mockAlice.userID)
    static let accountOwnerViewModel = makeViewModel(userID: RoomMemberProxyMock.mockMe.userID)
    
    static var previews: some View {
        UserProfileScreen(context: verifiedUserViewModel.context)
            .snapshotPreferences(expect: verifiedUserViewModel.context.$viewState.map { state in
                state.isVerified != nil
            })
            .previewDisplayName("Verified User")
        
        UserProfileScreen(context: otherUserViewModel.context)
            .snapshotPreferences(expect: otherUserViewModel.context.$viewState.map { state in
                state.isVerified != nil
            })
            .previewDisplayName("Other User")
        
        UserProfileScreen(context: accountOwnerViewModel.context)
            .snapshotPreferences(expect: accountOwnerViewModel.context.$viewState.map { state in
                state.isVerified != nil
            })
            .previewDisplayName("Account Owner")
    }
    
    static func makeViewModel(userID: String) -> UserProfileScreenViewModel {
        let clientProxyMock = ClientProxyMock(.init())
        clientProxyMock.userIdentityForClosure = { userID in
            let isVerified = userID == RoomMemberProxyMock.mockDan.userID
            return .success(UserIdentitySDKMock(configuration: .init(isVerified: isVerified)))
        }
        if userID != RoomMemberProxyMock.mockMe.userID {
            clientProxyMock.directRoomForUserIDReturnValue = .success("roomID")
        }
        return UserProfileScreenViewModel(userID: userID,
                                          isPresentedModally: false,
                                          clientProxy: clientProxyMock,
                                          mediaProvider: MediaProviderMock(configuration: .init()),
                                          userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                          analytics: ServiceLocator.shared.analytics)
    }
}
