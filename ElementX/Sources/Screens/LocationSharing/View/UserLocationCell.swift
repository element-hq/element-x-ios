//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct UserLocationCell: View {
    let profile: UserProfileProxy
    let isOwnUser: Bool
    let kind: Kind
    var mediaProvider: MediaProviderProtocol?
    
    var onShare: (() -> Void)?
    var onStop: (() -> Void)?
    
    enum Kind {
        case `static`(isUserLocation: Bool, timestamp: Date)
        case live
    }
    
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
            
            HStack(spacing: 16) {
                VStack(alignment: .leading, spacing: 0) {
                    Text(name)
                        .font(.compound.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                    HStack(spacing: 4) {
                        if case let .static(isUserLocation, timestamp) = kind {
                            CompoundIcon(isUserLocation ? \.locationNavigatorCentred : \.locationNavigator,
                                         size: .xSmall,
                                         relativeTo: .compound.bodyMD)
                                .foregroundStyle(.compound.iconSecondary)
                                .accessibilityLabel(isUserLocation ? L10n.a11ySenderLocation : L10n.a11yPinnedLocation)
                            Text(L10n.screenStaticLocationSheetTimestampDescription(timestamp.formatted(.relative(presentation: .named))))
                                .font(.compound.bodyMD)
                                .foregroundStyle(.compound.textSecondary)
                        } else {
                            CompoundIcon(\.locationPinSolid,
                                         size: .xSmall,
                                         relativeTo: .compound.bodyMD)
                                .foregroundStyle(.compound.iconAccentPrimary)
                                .accessibilityHidden(true)
                            Text(L10n.screenLiveLocationSheetSharingLiveLocation)
                                .font(.compound.bodyMD)
                                .foregroundStyle(.compound.textPrimary)
                        }
                    }
                }
                .accessibilityElement(children: .combine)
                
                Spacer()
                if case .live = kind, isOwnUser {
                    StopButton { onStop?() }
                }
                Button { onShare?() } label: {
                    CompoundIcon(\.shareIos)
                        .foregroundStyle(.compound.iconPrimary)
                        .padding(5)
                        .overlay(RoundedRectangle(cornerRadius: 99)
                            .inset(by: -0.5)
                            .stroke(.compound.borderInteractiveSecondary, lineWidth: 1))
                        .accessibilityLabel(L10n.actionShare)
                }
            }
            .padding(.vertical, 12)
            .rowDivider(alignment: .top)
        }
        .padding(.horizontal, 16)
    }
}

struct UserLocationCell_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        UserLocationCell(profile: .mockDan,
                         isOwnUser: true,
                         kind: .static(isUserLocation: true, timestamp: .mock),
                         mediaProvider: MediaProviderMock(configuration: .init()))
            .previewDisplayName("Stiatc user locaton")
            .previewLayout(.sizeThatFits)
        UserLocationCell(profile: .mockDan,
                         isOwnUser: false,
                         kind: .static(isUserLocation: false, timestamp: .mock),
                         mediaProvider: MediaProviderMock(configuration: .init()))
            .previewDisplayName("Static pin location")
            .previewLayout(.sizeThatFits)
        UserLocationCell(profile: .mockDan,
                         isOwnUser: true,
                         kind: .live,
                         mediaProvider: MediaProviderMock(configuration: .init()))
            .previewDisplayName("Live location")
            .previewLayout(.sizeThatFits)
    }
}
