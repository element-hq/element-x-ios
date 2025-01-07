//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import MatrixRustSDK
import SwiftUI

struct SessionVerificationRequestDetailsView: View {
    @ScaledMetric private var iconSize = 30.0
    private let outerShape = RoundedRectangle(cornerRadius: 8)
    
    let details: SessionVerificationRequestDetails
    
    var body: some View {
        VStack(spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 16) {
                    CompoundIcon(\.devices)
                        .frame(width: iconSize, height: iconSize)
                        .foregroundColor(.compound.iconSecondary)
                        .padding(6)
                        .background(.compound.bgSubtleSecondary)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    
                    Text(details.displayName ?? details.senderID)
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
            
            Text(L10n.screenSessionVerificationRequestFooter)
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.compound.textPrimary)
        }
    }
}

struct SessionVerificationRequestDetailsView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let details = SessionVerificationRequestDetails(senderID: "@bob:matrix.org",
                                                        flowID: "123",
                                                        deviceID: "CODEMISTAKE",
                                                        displayName: "Bob's Element X iOS",
                                                        firstSeenDate: .init(timeIntervalSince1970: 0))
        
        SessionVerificationRequestDetailsView(details: details)
    }
}
