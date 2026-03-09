//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct StaticLocationSheet: View {
    @Bindable var context: LocationSharingScreenViewModel.Context
    @State private var height = CGFloat.zero
    
    /// Fixes an iOS 26 sheet issue
    /// if the content doesn't meet a certain size
    /// additional insets are added.
    private let additionalHeight: CGFloat = 14
    
    var body: some View {
        mainContent
            .readHeight($height)
            .interactiveDismissDisabled()
            .presentationBackground(.compound.bgCanvasDefault)
            .presentationBackgroundInteraction(.enabled)
            .presentationDragIndicator(.hidden)
            .presentationDetents([.height(height + additionalHeight)])
    }
    
    private var mainContent: some View {
        VStack(spacing: 0) {
            Text(L10n.screenStaticLocationSheetTitle)
                .foregroundStyle(.compound.textPrimary)
                .font(.compound.bodyLGSemibold)
                .padding(.bottom, 25)
                .padding(.top, 29)
            if case let .viewStatic(location) = context.viewState.interactionMode,
               let userProfile = context.viewState.userProfile {
                Button {
                    context.showShareSheet = true
                } label: {
                    UserLocationCell(profile: userProfile,
                                     isOwnUser: userProfile.userID == context.viewState.ownUserID,
                                     isUserLocation: location.kind == .sender,
                                     timestamp: location.timestamp,
                                     mediaProvider: context.mediaProvider)
                }
            }
        }
    }
}

/// This may be reused for live location sharing sheet in the future with some tweaks
private struct UserLocationCell: View {
    let profile: UserProfileProxy
    let isOwnUser: Bool
    let isUserLocation: Bool
    let timestamp: Date
    var mediaProvider: MediaProviderProtocol?
    
    private var name: String {
        isOwnUser ? L10n.commonYou : profile.displayName ?? profile.userID
    }
    
    var body: some View {
        HStack(spacing: 12) {
            LoadableAvatarImage(url: profile.avatarURL,
                                name: profile.displayName,
                                contentID: profile.id,
                                avatarSize: .user(on: .map),
                                mediaProvider: mediaProvider)
                .accessibilityHidden(true)
            
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(name)
                        .font(.compound.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                    HStack(spacing: 4) {
                        CompoundIcon(isUserLocation ? \.locationNavigatorCentred : \.locationNavigator,
                                     size: .xSmall,
                                     relativeTo: .compound.bodyMD)
                            .foregroundStyle(.compound.iconSecondary)
                            .accessibilityLabel(isUserLocation ? L10n.a11ySenderLocation : L10n.a11yPinnedLocation)
                        Text(L10n.screenStaticLocationSheetTimestampDescription(timestamp.formatted(.relative(presentation: .named))))
                            .font(.compound.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                    }
                }
                
                Spacer()
                CompoundIcon(\.shareIos)
                    .foregroundStyle(.compound.iconSecondary)
                    .accessibilityLabel(L10n.actionShare)
            }
            .padding(.vertical, 12)
            .rowDivider(alignment: .top)
        }
        .padding(.horizontal, 16)
        .accessibilityElement(children: .combine)
    }
}

struct StaticLocationSheet_Previews: PreviewProvider, TestablePreview {
    static let viewModel = LocationSharingScreenViewModel.mock(type: .staticSenderLocation, senderID: RoomMemberProxyMock.mockMe.userID)
    
    static let pinViewModel = LocationSharingScreenViewModel.mock(type: .staticPinLocation)
    
    static var previews: some View {
        StaticLocationSheet(context: viewModel.context)
            .previewDisplayName("Static own location")
        StaticLocationSheet(context: pinViewModel.context)
            .previewDisplayName("Static pin location")
    }
}
