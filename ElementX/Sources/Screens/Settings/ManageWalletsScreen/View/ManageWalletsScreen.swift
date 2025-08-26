//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ManageWalletsScreen: View {
    @ObservedObject var context: ManageWalletsViewModel.Context
    
    var body: some View {
        Form {
            EmptyView()
        }
        .zeroList()
        .navigationTitle("Wallets")
        .navigationBarTitleDisplayMode(.inline)
    }
}
