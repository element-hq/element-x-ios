//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpaceHeaderTopicSheetView: View {
    let topic: String
    
    @State private var sheetHeight: CGFloat = .zero
    private let topPadding: CGFloat = 19
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 10) {
                Text(L10n.commonDescription)
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textSecondary)
                    .textCase(.uppercase)
                Text(topic)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .readHeight($sheetHeight)
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(.top, topPadding) // For the drag indicator
        .presentationDetents([.height(sheetHeight + topPadding)])
        .presentationDragIndicator(.visible)
        .presentationBackground(.compound.bgCanvasDefault)
    }
}

// MARK: - Previews

struct SpaceHeaderTopicSheetView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        SpaceHeaderTopicSheetView(topic: ["Description of the space goes right here.",
                                          "Lorem ipsum dolor sit amet consectetur.",
                                          "Leo viverra morbi habitant in.",
                                          "Sem amet enim habitant nibh augue mauris.",
                                          "Interdum mauris ultrices tincidunt proin morbi erat aenean risus nibh.",
                                          "Diam amet sit fermentum vulputate faucibus."].joined(separator: " "))
    }
}
