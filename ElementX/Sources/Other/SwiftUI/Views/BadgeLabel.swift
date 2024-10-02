//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        isHighlighted ? .compound._badgeTextSuccess : .compound._badgeTextSubtle
    }
    
    var iconColor: Color {
        isHighlighted ? .compound.iconSuccessPrimary : .compound.iconSecondary
    }
    
    var backgroundColor: Color {
        isHighlighted ? .compound._bgBadgeSuccess : .compound.bgSubtlePrimary
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
