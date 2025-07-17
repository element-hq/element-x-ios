//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct ClaimEarningsButton: View {
    var text: String = "Claim Earnings"
    let onTap: () -> Void
    
    var body: some View {
        Button {
             onTap()
        } label: {
            HStack {
                Image(asset: Asset.Images.iconClaimRewards)
                Text(text)
                    .font(.compound.bodySMSemibold)
                    .foregroundStyle(.zero.bgAccentRest)
            }
        }
    }
}
