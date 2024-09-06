//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension LabelStyle where Self == CustomLayoutLabelStyle {
    /// A label style that uses an `HStack` with parameters to customise the label's layout.
    static func custom(spacing: CGFloat, alignment: VerticalAlignment = .center, iconLayout: Self.IconLayout = .leading) -> Self {
        CustomLayoutLabelStyle(spacing: spacing, alignment: alignment, iconLayout: iconLayout)
    }
}

struct CustomLayoutLabelStyle: LabelStyle {
    let spacing: CGFloat
    var alignment: VerticalAlignment
    
    enum IconLayout {
        case leading
        case trailing
    }
    
    var iconLayout: IconLayout
    
    fileprivate init(spacing: CGFloat, alignment: VerticalAlignment, iconLayout: IconLayout) {
        self.spacing = spacing
        self.alignment = alignment
        self.iconLayout = iconLayout
    }
    
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: alignment, spacing: spacing) {
            switch iconLayout {
            case .leading:
                configuration.icon
                configuration.title
            case .trailing:
                configuration.title
                configuration.icon
            }
        }
    }
}
