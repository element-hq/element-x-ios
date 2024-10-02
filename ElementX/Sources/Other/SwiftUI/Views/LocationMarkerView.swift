//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct LocationMarkerView: View {
    private let pinColor: Color = .compound.iconOnSolidPrimary
    private let pinInsets = EdgeInsets(top: 13, leading: 12, bottom: 15, trailing: 12)
    
    var body: some View {
        CompoundIcon(\.locationPinSolid)
            .dynamicTypeSize(.large)
            .foregroundStyle(pinColor)
            .padding(pinInsets)
            .background {
                backgroundShape
                    .shadow(color: .black.opacity(0.2), radius: 4.1129, x: 0, y: 4.93548)
            }
            .alignmentGuide(VerticalAlignment.center) { dimensions in
                dimensions[.bottom]
            }
    }
    
    var backgroundShape: some View {
        Image(asset: Asset.Images.locationMarkerShape)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .foregroundStyle(.compound.iconPrimary)
    }
}

struct LocationMarkerView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 30) {
            LocationMarkerView()

            LocationMarkerView()
                .colorScheme(.dark)
        }
    }
}
