//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct BadgeLabel: View {
    let title: String
    let icon: KeyPath<CompoundIcons, Image>
    let isHighlighted: Bool
    
    var body: some View {
        Label(title,
              icon: icon,
              iconSize: .xSmall,
              relativeTo: .compound.bodySM)
            .labelStyle(BadgeLabelStyle(isHighlighted: isHighlighted))
    }
}

private struct BadgeLabelStyle: LabelStyle {
    let isHighlighted: Bool
    
    var titleColor: Color {
        isHighlighted ? .compound.textBadgeAccent : .compound.textBadgeInfo
    }
    
    var iconColor: Color {
        isHighlighted ? .compound.iconSuccessPrimary : .compound.iconInfoPrimary
    }
    
    var backgroundColor: Color {
        isHighlighted ? .compound.bgBadgeAccent : .compound.bgBadgeInfo
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: 4) {
            configuration.icon
                .foregroundStyle(iconColor)
            configuration.title
                .foregroundStyle(titleColor)
        }
        .font(.compound.bodySM)
        .padding(.leading, 8)
        .padding(.trailing, 12)
        .padding(.vertical, 4)
        .background(Capsule().fill(backgroundColor))
    }
}

struct BadgeLabel_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 10) {
            BadgeLabel(title: "Encrypted",
                       icon: \.lockSolid,
                       isHighlighted: true)
            BadgeLabel(title: "Not encrypted",
                       icon: \.lockSolid,
                       isHighlighted: false)
        }
    }
}
