//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct StopButton: View {
    let stopAction: () -> Void
    
    var body: some View {
        Button { stopAction() } label: {
            CompoundIcon(\.stop, size: .small, relativeTo: .compound.bodySMSemibold)
                .foregroundStyle(.compound.iconOnSolidPrimary)
                .padding(8)
                .background(Color.compound.bgCriticalPrimary, in: Circle())
                .accessibilityLabel(L10n.actionStop)
        }
    }
}
