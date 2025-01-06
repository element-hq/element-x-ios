//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct KnockRequestsListEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.askToJoin)
            VStack(spacing: 8) {
                Text(L10n.screenKnockRequestsListEmptyStateTitle)
                    .multilineTextAlignment(.center)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                Text(L10n.screenKnockRequestsListEmptyStateDescription)
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.compound.textSecondary)
                    .font(.compound.bodyMD)
            }
            Spacer()
        }
        .padding(.top, 53)
        .padding(.horizontal, 40)
    }
}

// MARK: - Previews

struct KnockRequestsListEmptyStateView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        KnockRequestsListEmptyStateView()
    }
}
