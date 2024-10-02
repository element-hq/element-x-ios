//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

struct RoundedLabelItem<Icon: View>: View {
    @Environment(\.backgroundStyle) private var backgroundStyle
    
    let title: String
    let listPosition: ListPosition
    let iconContent: () -> Icon
    
    private var backgroundColor: AnyShapeStyle {
        backgroundStyle ?? AnyShapeStyle(.compound.bgSubtleSecondary)
    }
    
    var body: some View {
        Label { Text(title) } icon: {
            iconContent()
        }
        .labelStyle(CheckmarkLabelStyle())
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(backgroundColor, in: RoundedCornerShape(radius: 16, corners: listPosition.roundedCorners))
    }
}

private struct CheckmarkLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .top, spacing: 16) {
            configuration.icon
            configuration.title
        }
        .font(.compound.bodyMD)
        .foregroundColor(.compound.textPrimary)
    }
}

// MARK: - Previews

struct AnalyticsPromptScreenCheckmarkItem_Previews: PreviewProvider, TestablePreview {
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
            RoundedLabelItem(title: strings.point1, listPosition: .top) {
                testImage1
            }
            RoundedLabelItem(title: strings.point2, listPosition: .middle) {
                testImage2
            }
            RoundedLabelItem(title: "This is a short string.", listPosition: .middle) {
                testImage1
            }
            RoundedLabelItem(title: "This is a very long string that will be used to test the layout over multiple lines of text to ensure everything is correct.",
                             listPosition: .bottom) {
                testImage2
            }
        }
        .padding()
    }
}
