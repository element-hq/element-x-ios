//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct BadgeLabel: View {
    enum Style {
        case accent
        case info
        case `default`
    }
    
    let title: String
    let icon: KeyPath<CompoundIcons, Image>
    let style: Style
    
    var body: some View {
        Label(title,
              icon: icon,
              iconSize: .small,
              relativeTo: .compound.bodySM)
            .labelStyle(LabelStyle(style: style))
    }
    
    private struct LabelStyle: SwiftUI.LabelStyle {
        let style: Style
        
        var titleColor: Color {
            switch style {
            case .accent: .zero._badgeTextSuccess
            case .info: .compound.textBadgeInfo
            case .default: .compound.textPrimary
            }
        }
        
        var iconColor: Color {
            switch style {
            case .accent: .zero.iconSuccessPrimary
            case .info: .compound.iconSecondary
            case .default: .compound.iconSecondary
            }
        }
        
        var backgroundColor: Color {
            switch style {
            case .accent: .zero._bgBadgeSuccess
            case .info: .compound.bgBadgeInfo
            case .default: .compound.bgBadgeDefault
            }
        }
        
        func makeBody(configuration: Configuration) -> some View {
//            HStack(spacing: 4) {
//                configuration.icon
//                    .foregroundStyle(iconColor)
//                configuration.title
//                    .foregroundStyle(titleColor)
//            }
//            .font(.zero.bodySM)
//            .padding(.leading, 8)
//            .padding(.trailing, 12)
//            .padding(.vertical, 4)
//            .background(Capsule().fill(backgroundColor))
            HStack {
                configuration.icon
                    .foregroundStyle(iconColor)
            }
        }
    }
}

struct BadgeLabel_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 10) {
            BadgeLabel(title: "Encrypted",
                       icon: \.lockSolid,
                       style: .accent)
            BadgeLabel(title: "Not encrypted",
                       icon: \.lockSolid,
                       style: .info)
            BadgeLabel(title: "1234",
                       icon: \.userProfile,
                       style: .default)
        }
    }
}
