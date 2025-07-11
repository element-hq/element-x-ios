//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ZeroSettingsBenefitRow: View {
    let title: String
    let description: String
    
    var body: some View {
        HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 0) {
                Text(title)
                    .font(.compound.bodyMDSemibold)
                    .foregroundColor(.compound.textPrimary)
                
                Text(description)
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
                    .padding(.top, 1)
            }
            
            Spacer()
            
            Image(asset: Asset.Images.checkIcon)
                .resizable()
                .renderingMode(.template)
                .foregroundStyle(.zero.bgAccentRest)
                .frame(width: 20, height: 20)
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(.compound.bgCanvasDisabled)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .padding(.vertical, 1)
    }
}
