//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LiveLocationSharingBannerView: View {
    var onStop: () -> Void
    
    var body: some View {
        HStack(spacing: 9) {
            CompoundIcon(\.locationPinSolid, size: .medium, relativeTo: .compound.bodyMDSemibold)
                .foregroundColor(Color.compound.iconSuccessPrimary)
                .accessibilityHidden(true)
            Text(L10n.screenRoomLiveLocationBanner)
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.compound.textPrimary)
            Spacer()
            Button(L10n.actionStop, role: .destructive, action: onStop)
                .buttonStyle(.compound(.primary, size: .small))
        }
        .padding(.vertical, 16)
        .padding(.horizontal, 15)
        .background(Color.compound.bgCanvasDefault)
        .overlay(alignment: .top) { Color.compound.separatorPrimary.frame(height: 1) }
        .overlay(alignment: .bottom) { Color.compound.separatorPrimary.frame(height: 1) }
    }
}

struct LiveLocationSharingBannerView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        LiveLocationSharingBannerView { }
            .previewLayout(.sizeThatFits)
    }
}
