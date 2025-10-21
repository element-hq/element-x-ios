//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import MatrixRustSDK
import SwiftUI

struct SessionVerificationRequestDetailsView: View {
    @ScaledMetric private var iconSize = 30.0
    private let outerShape = RoundedRectangle(cornerRadius: 8)
    
    let details: SessionVerificationRequestDetails
    let isUserVerification: Bool
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        if isUserVerification {
            userRequestDetails
        } else {
            deviceRequestDetails
        }
    }
    
    private var userRequestDetails: some View {
        HStack(spacing: 12) {
            LoadableAvatarImage(url: details.senderProfile.avatarURL,
                                name: details.senderProfile.displayName,
                                contentID: details.senderProfile.userID,
                                avatarSize: .user(on: .sessionVerification),
                                mediaProvider: mediaProvider)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(details.senderProfile.displayName ?? details.senderProfile.userID)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
                
                if details.senderProfile.displayName != nil {
                    Text(details.senderProfile.userID)
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textPrimary)
                }
            }
        }
        .accessibilityElement(children: .combine)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(.compound.bgSubtleSecondary)
        .clipShape(outerShape)
    }
    
    private var deviceRequestDetails: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    CompoundIcon(\.devices)
                        .frame(width: iconSize, height: iconSize)
                        .foregroundColor(.compound.iconSecondary)
                        .padding(6)
                        .background(.compound.bgSubtleSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    let displayName = isUserVerification ? details.senderProfile.displayName : details.deviceDisplayName
                    Text(displayName ?? details.senderProfile.userID)
                        .font(.compound.bodyMDSemibold)
                        .foregroundColor(.compound.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                HStack(spacing: 40) {
                    VStack(alignment: .leading, spacing: 0) {
                        Text(L10n.screenSessionVerificationRequestDetailsTimestamp)
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                        Text(details.firstSeenDate.formattedMinimal())
                            .font(.compound.bodyMD)
                            .foregroundColor(.compound.textPrimary)
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(L10n.commonDeviceId)
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                        Text(details.deviceID)
                            .font(.compound.bodyMD)
                            .foregroundColor(.compound.textPrimary)
                    }
                }
            }
            .padding(24)
            .clipShape(outerShape)
            .overlay {
                outerShape
                    .inset(by: 0.25)
                    .stroke(.compound.borderDisabled)
            }
            
            .font(.compound.bodyMDSemibold)
            
            Text(L10n.screenSessionVerificationRequestFooter)
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.compound.textPrimary)
        }
    }
}

struct SessionVerificationRequestDetailsView_Previews: PreviewProvider, TestablePreview {
    static let details = SessionVerificationRequestDetails(senderProfile: UserProfileProxy(userID: "@bob:matrix.org",
                                                                                           displayName: "Billy bob",
                                                                                           avatarURL: .mockMXCUserAvatar),
                                                           flowID: "123",
                                                           deviceID: "CODEMISTAKE",
                                                           deviceDisplayName: "Bob's Element X iOS",
                                                           firstSeenDate: .init(timeIntervalSince1970: 0))
    
    static var previews: some View {
        SessionVerificationRequestDetailsView(details: details,
                                              isUserVerification: true,
                                              mediaProvider: MediaProviderMock(configuration: .init()))
            .padding()
            .previewDisplayName("User")
        
        SessionVerificationRequestDetailsView(details: details,
                                              isUserVerification: false,
                                              mediaProvider: MediaProviderMock(configuration: .init()))
            .padding()
            .previewDisplayName("Device")
    }
}
