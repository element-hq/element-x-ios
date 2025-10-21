//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct HomeScreenNewSoundBanner: View {
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 16) {
            content
            buttons
        }
        .padding(16)
        .background(Color.compound.bgSubtleSecondary)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
    
    var content: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(alignment: .firstTextBaseline, spacing: 16) {
                Text(L10n.bannerNewSoundTitle)
                    .font(.compound.bodyLGSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Button(action: dismissAction) {
                    Image(systemName: "xmark")
                        .foregroundColor(.compound.iconSecondary)
                        .frame(width: 12, height: 12)
                }
            }
            
            Text(L10n.bannerNewSoundMessage)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
        }
    }
    
    var buttons: some View {
        Button(action: dismissAction) {
            Text(L10n.actionOk)
                .frame(maxWidth: .infinity)
        }
        .buttonStyle(.compound(.primary, size: .medium))
    }
}

struct HomeScreenNewSoundBanner_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HomeScreenNewSoundBanner { }
    }
}
