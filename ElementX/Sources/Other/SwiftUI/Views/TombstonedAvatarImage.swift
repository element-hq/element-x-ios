//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct TombstonedAvatarImage: View {
    @ScaledMetric private var frameSize: CGFloat
    
    init(avatarSize: Avatars.Size) {
        _frameSize = ScaledMetric(wrappedValue: avatarSize.value)
    }
    
    var body: some View {
        GeometryReader { geometry in
            ZStack(alignment: .center) {
                Color.compound.bgSubtlePrimary
                
                Text(verbatim: "!")
                    .foregroundColor(.compound.iconTertiary)
                    .font(.system(size: geometry.size.width * 0.5625, weight: .semibold))
                    .minimumScaleFactor(0.001)
                    .frame(alignment: .center)
                    .accessibilityLabel(L10n.a11yTombstonedRoom)
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .frame(width: frameSize, height: frameSize)
        .background(Color.compound.bgCanvasDefault)
        .clipShape(Circle())
    }
}

struct TombstonedAvatarImage_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        TombstonedAvatarImage(avatarSize: .room(on: .chats))
            .previewLayout(.sizeThatFits)
    }
}
