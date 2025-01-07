//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension ButtonStyle where Self == MenuSheetButtonStyle {
    /// A button style for buttons that are within a menu that is being presented as a sheet.
    static var menuSheet: Self { MenuSheetButtonStyle() }
}

/// The style used for buttons that are part of a menu that's presented as
/// a sheet such as `TimelineItemMenu`.
struct MenuSheetButtonStyle: ButtonStyle {
    @Environment(\.accessibilityShowButtonShapes) private var accessibilityShowButtonShapes
    
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .labelStyle(MenuSheetLabelStyle())
            .foregroundStyle(configuration.role == .destructive ? .compound.textCriticalPrimary : .compound.textActionPrimary)
            .contentShape(.rect)
            .opacity(configuration.isPressed ? 0.3 : 1)
            .background {
                if accessibilityShowButtonShapes {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(uiColor: .secondarySystemFill))
                        .opacity(configuration.isPressed ? 0.8 : 1)
                        .padding(4)
                }
            }
    }
}

private struct MenuSheetLabelStyle: LabelStyle {
    var spacing: CGFloat = 16
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(spacing: spacing) {
            configuration.icon
            configuration.title
        }
        .multilineTextAlignment(.leading)
        .frame(maxWidth: .infinity, alignment: .leading)
        .fixedSize(horizontal: false, vertical: true)
        .padding(16)
    }
}
