//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Represents the position of a checkmark item in a list.
enum ListPosition {
    case top, middle, bottom

    /// The corners that should be rounded for this position.
    var roundedCorners: UIRectCorner {
        switch self {
        case .top:
            return [.topLeft, .topRight]
        case .middle:
            return []
        case .bottom:
            return [.bottomLeft, .bottomRight]
        }
    }
}

struct VisualListItem<Icon: View>: View {
    let title: String
    let position: ListPosition
    let iconContent: () -> Icon
    
    var body: some View {
        Label { Text(title) } icon: {
            iconContent()
        }
        .labelStyle(VisualListItemLabelStyle())
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(.compound.bgSubtleSecondary, in: RoundedCornerShape(radius: 14, corners: position.roundedCorners))
    }
}

private struct VisualListItemLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 12) {
            configuration.icon
            configuration.title
        }
        .font(.compound.bodyMD)
        .foregroundColor(.compound.textPrimary)
    }
}

// MARK: - Previews

struct VisualListItem_Previews: PreviewProvider, TestablePreview {
    static let strings = AnalyticsPromptScreenStrings(termsURL: ServiceLocator.shared.settings.analyticsConfiguration.termsURL)

    @ViewBuilder
    static var testImage1: some View {
        Image(systemName: "circle")
    }

    @ViewBuilder
    static var testImage2: some View {
        Image(systemName: "square")
    }
    
    static var previews: some View {
        VStack(alignment: .leading, spacing: 4) {
            VisualListItem(title: strings.point1, position: .top) {
                testImage1
            }
            VisualListItem(title: strings.point2, position: .middle) {
                testImage2
            }
            VisualListItem(title: "This is a short string.", position: .middle) {
                testImage1
            }
            VisualListItem(title: "This is a very long string that will be used to test the layout over multiple lines of text to ensure everything is correct.",
                           position: .bottom) {
                testImage2
            }
        }
        .padding()
    }
}
