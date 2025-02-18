//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct VerificationBadge: View {
    let verificationState: UserIdentityVerificationState
    
    var body: some View {
        switch verificationState {
        case .verified:
            CompoundIcon(\.verified, size: .small, relativeTo: .compound.bodyMD)
                .foregroundStyle(.compound.iconSuccessPrimary)
        case .verificationViolation:
            CompoundIcon(\.infoSolid, size: .small, relativeTo: .compound.bodyMD)
                .foregroundStyle(.compound.iconCriticalPrimary)
        case .notVerified:
            EmptyView()
        }
    }
}

struct VerificationBadge_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 16.0) {
            VerificationBadge(verificationState: .notVerified)
            VerificationBadge(verificationState: .verificationViolation)
            VerificationBadge(verificationState: .verified)
        }
        .previewLayout(.sizeThatFits)
    }
}
