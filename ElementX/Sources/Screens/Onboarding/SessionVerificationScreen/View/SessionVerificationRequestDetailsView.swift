//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SessionVerificationRequestDetailsView: View {
    let details: SessionVerificationRequestDetails
    let ownProfile: UserProfile
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
        AccountInfoCardView(userProfile: ownProfile,
                            style: .userVerification(senderProfile: details.senderProfile),
                            mediaProvider: mediaProvider)
    }
    
    private var deviceRequestDetails: some View {
        VStack(spacing: 24) {
            AccountInfoCardView(userProfile: ownProfile,
                                style: .deviceVerification(.init(deviceID: details.deviceID,
                                                                 displayName: details.deviceDisplayName ?? details.senderProfile.id,
                                                                 firstSeenDate: details.firstSeenDate)),
                                mediaProvider: mediaProvider)
            
            Text(L10n.screenSessionVerificationRequestFooter)
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.compound.textPrimary)
        }
    }
}

struct SessionVerificationRequestDetailsView_Previews: PreviewProvider, TestablePreview {
    static let details = SessionVerificationRequestDetails(senderProfile: UserProfile(userID: "@bob:matrix.org",
                                                                                      displayName: "Billy bob",
                                                                                      avatarURL: .mockMXCUserAvatar),
                                                           flowID: "123",
                                                           deviceID: "CODEMISTAKE",
                                                           deviceDisplayName: "Bob's Element X iOS",
                                                           firstSeenDate: .init(timeIntervalSince1970: 0))
    
    static var previews: some View {
        SessionVerificationRequestDetailsView(details: details,
                                              ownProfile: .mockCharlie,
                                              isUserVerification: true,
                                              mediaProvider: MediaProviderMock(.init()))
            .padding()
            .previewDisplayName("User")
        
        SessionVerificationRequestDetailsView(details: details,
                                              ownProfile: .mockCharlie,
                                              isUserVerification: false,
                                              mediaProvider: MediaProviderMock(.init()))
            .padding()
            .previewDisplayName("Device")
    }
}
