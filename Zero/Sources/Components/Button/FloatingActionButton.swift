//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct FloatingActionButton: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: {
           onTap()
        }) {
            Image(systemName: "plus")
                .font(.system(size: 20))
                .foregroundColor(.black)
                .padding()
                .background(.zero.bgAccentRest)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .shadow(radius: 5)
        }
        .padding()
    }
}
