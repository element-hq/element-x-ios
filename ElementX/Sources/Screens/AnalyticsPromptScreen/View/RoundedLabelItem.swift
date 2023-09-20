//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
    let title: String
    let listPosition: ListPosition
    let iconContent: () -> Icon
    
    var body: some View {
        Label { Text(title) } icon: {
            iconContent()
        }
        .labelStyle(CheckmarkLabelStyle())
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.compound.bgSubtleSecondary, in: RoundedCornerShape(radius: 16, corners: listPosition.roundedCorners))
    }
}

private struct CheckmarkLabelStyle: LabelStyle {
    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 16) {
            configuration.icon
                .font(.compound.bodyLGSemibold)
            configuration.title
                .font(.compound.bodyMDSemibold)
        }
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
