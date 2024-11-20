//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct KnockRequestsListEmptyStateView: View {
    var body: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.askToJoin)
            VStack(spacing: 8) {
                Text("No pending request to join")
                    .multilineTextAlignment(.center)
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                Text("When somebody will ask to join the room, you’ll be able to see their request here.")
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
