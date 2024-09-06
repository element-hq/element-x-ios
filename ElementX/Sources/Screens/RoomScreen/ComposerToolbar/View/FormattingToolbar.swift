//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct FormattingToolbar: View {
    /// The list of items to render in the toolbar
    var formatItems: [FormatItem]
    /// The action when an item is selected
    var formatAction: (FormatType) -> Void

    var body: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 4) {
                ForEach(formatItems) { item in
                    Button {
                        formatAction(item.type)
                    } label: {
                        CompoundIcon(item.icon, size: .small, relativeTo: .compound.headingLG)
                            .foregroundColor(item.foregroundColor)
                            .padding(8)
                            .background(item.backgroundColor)
                            .cornerRadius(8)
                            .padding(4)
                    }
                    .disabled(item.state == .disabled)
                    .accessibilityIdentifier(item.accessibilityIdentifier)
                    .accessibilityLabel(item.accessibilityLabel)
                }
            }
        }
    }
}

private extension FormatItem {
    var foregroundColor: Color {
        switch state {
        case .reversed:
            return .compound.iconSuccessPrimary
        case .enabled:
            return .compound.iconSecondary
        case .disabled:
            return .compound.iconDisabled
        }
    }

    var backgroundColor: Color {
        switch state {
        case .reversed:
            return .compound._bgAccentSelected
        case .enabled, .disabled:
            return .compound.bgCanvasDefault
        }
    }
}

struct FormattingToolbar_Previews: PreviewProvider, TestablePreview {
    static let items = FormatType.allCases.map { FormatItem(type: $0, state: .enabled) }
    static let disabledItems = FormatType.allCases.map { FormatItem(type: $0, state: .disabled) }
    
    static var previews: some View {
        VStack(spacing: 16.0) {
            FormattingToolbar(formatItems: items) { _ in }
            FormattingToolbar(formatItems: disabledItems) { _ in }
        }
    }
}
