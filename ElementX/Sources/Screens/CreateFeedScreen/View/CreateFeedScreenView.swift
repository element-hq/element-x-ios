//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct CreateFeedScreen: View {
    @ObservedObject var context: CreateFeedScreenViewModel.Context
    
    var body: some View {
        HStack {
            Text("Create a feed")
                .font(.headline)
            Spacer()
        }
        .padding()
    }
}
