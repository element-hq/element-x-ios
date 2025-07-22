//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ClaimEarningsButton: View {
    var text: String = "Claim Earnings"
    var disabled: Bool = false
    let onTap: () -> Void
    
    var body: some View {
        HStack {
            Button {
                 onTap()
            } label: {
                HStack {
                    Image(asset: Asset.Images.iconClaimRewards)
                        .renderingMode(.template)
                        .foregroundStyle(disabled ? .compound.iconDisabled : .zero.bgAccentRest)
                    Text(text)
                        .font(.compound.bodyMDSemibold)
                        .foregroundStyle(disabled ? .compound.iconDisabled : .zero.bgAccentRest)
                }
            }
            .disabled(disabled)
        }
    }
}

//struct NoEarningsInfo: View {
//    @State private var showTooltip = false
//
//    var body: some View {
//        ZStack {
//            Button(action: {
//                showTooltip.toggle()
//            }) {
//                CompoundIcon(\.info, size: .small, relativeTo: .compound.bodyMDSemibold)
//                    .foregroundStyle(.compound.iconSecondary)
//            }
//            if showTooltip {
//                tooltip
//                    .offset(y: -25)
//            }
//        }
//        .onChange(of: showTooltip) { _, newValue in
//            if newValue {
//                DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
//                    showTooltip = false
//                }
//            }
//        }
//    }
//    
//    var tooltip: some View {
//        Text("No earnings available to claim.")
//            .padding(8)
//            .background(
//                RoundedRectangle(cornerRadius: 8)
//                    .fill(Color(.systemGray6))
//                    .shadow(radius: 2)
//            )
//            .foregroundColor(.primary)
//            .transition(.opacity.combined(with: .scale))
//    }
//}
