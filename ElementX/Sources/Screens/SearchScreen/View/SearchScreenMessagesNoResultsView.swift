//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SearchScreenMessagesNoResultsView: View {
    let query: String
    let onLearnMore: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            TitleAndIcon(title: UntranslatedL10n.screenSearchMessagesNoResultsTitle,
                         subtitle: UntranslatedL10n.screenSearchMessagesNoResultsMessage(query),
                         icon: \.search,
                         iconStyle: .defaultSolid)
            
            // The compound text link style has no accent colour variant.
            Button(action: onLearnMore) {
                Text(L10n.actionLearnMore)
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(.compound.textActionAccent)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(40)
    }
}

// MARK: - Previews

struct SearchScreenMessagesNoResultsView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        SearchScreenMessagesNoResultsView(query: "Offsite budget") { }
            .frame(maxHeight: .infinity, alignment: .top)
    }
}
