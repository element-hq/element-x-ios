//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct AccountInfoCardView: View {
    enum Style {
        case plain
        case deviceVerification(DeviceVerificationDetails)
        case userVerification(senderProfile: UserProfile)
    }
    
    struct DeviceVerificationDetails {
        let deviceID: String
        let displayName: String
        let firstSeenDate: Date
    }
    
    let userProfile: UserProfile
    var style: Style = .plain
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        VStack(spacing: 0) {
            UserProfileDetailsView(userProfile: userProfile, mediaProvider: mediaProvider)
            
            switch style {
            case .deviceVerification(let details):
                separator
                
                DeviceVerificationDetailsView(details: details)
            case .userVerification(let senderProfile):
                separator
                
                UserVerificationDetailsView(senderProfile: senderProfile, mediaProvider: mediaProvider)
            case .plain:
                EmptyView()
            }
        }
        .padding(20)
        .background {
            RoundedRectangle(cornerRadius: 8)
                .stroke(.compound.borderDisabled)
                .background(.compound.bgCanvasDefault, in: .rect(cornerRadius: 8))
        }
    }
    
    var separator: some View {
        Color.compound.separatorPrimary
            .frame(height: 1)
            .padding(.vertical, 20)
    }
}

private struct UserProfileDetailsView: View {
    let userProfile: UserProfile
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        HStack(spacing: 12) {
            LoadableAvatarImage(url: userProfile.avatarURL,
                                name: userProfile.displayName,
                                contentID: userProfile.id,
                                avatarSize: .user(on: .accountInfoCard),
                                mediaProvider: mediaProvider)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(userProfile.displayName ?? userProfile.id)
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(.compound.textPrimary)
                
                if userProfile.displayName != nil {
                    Text(userProfile.id)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .accessibilityElement(children: .combine)
    }
}

private struct UserVerificationDetailsView: View {
    let senderProfile: UserProfile
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(L10n.screenSessionVerificationUserRequestingVerification)
                .font(.compound.bodySM)
                .foregroundStyle(.compound.textSecondary)
            
            UserProfileDetailsView(userProfile: senderProfile, mediaProvider: mediaProvider)
        }
    }
}

private struct DeviceVerificationDetailsView: View {
    let details: AccountInfoCardView.DeviceVerificationDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                CompoundIcon(\.devices, size: .medium, relativeTo: .compound.bodyMDSemibold)
                    .foregroundStyle(.compound.iconSecondary)
                    .padding(6)
                    .background(.compound.bgSubtleSecondary, in: .rect(cornerRadius: 8))
                
                Text(details.displayName)
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(.compound.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            HStack(alignment: .top, spacing: 24) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.screenSessionVerificationRequestDetailsTimestamp)
                        .font(.compound.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                    Text(details.firstSeenDate.formattedMinimal())
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(L10n.commonDeviceId)
                        .font(.compound.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                    Text(details.deviceID)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .accessibilityElement(children: .combine)
            }
            .padding(.bottom, 5)
        }
    }
}

// MARK: - Previews

struct AccountInfoCardView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 20) {
            AccountInfoCardView(userProfile: .mockDan, mediaProvider: MediaProviderMock(.init()))
            AccountInfoCardView(userProfile: .mockBob, mediaProvider: MediaProviderMock(.init()))
            
            AccountInfoCardView(userProfile: .mockAlice,
                                style: .deviceVerification(.init(deviceID: "XXXXXXXXXX",
                                                                 displayName: "Element Web: macOS",
                                                                 firstSeenDate: .mock)),
                                mediaProvider: MediaProviderMock(.init()))
            
            AccountInfoCardView(userProfile: .mockAlice,
                                style: .userVerification(senderProfile: .mockDan),
                                mediaProvider: MediaProviderMock(.init()))
        }
        .padding(20)
        .previewLayout(.sizeThatFits)
    }
}
