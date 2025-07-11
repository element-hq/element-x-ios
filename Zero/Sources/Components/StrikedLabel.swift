//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct StrikedLabel: View {
    var text: String
    var textColor: Color = .compound.textSecondary
    var strikeColor: Color = .compound.textSecondary
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(strikeColor.opacity(0.4))
                .frame(height: 1)
            
            Text(text)
                .font(.compound.bodySM)
                .foregroundColor(textColor)
                .padding(.horizontal, 10)
                .background(.zero.bgCanvasDefault)
        }
    }
}
