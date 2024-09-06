//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct EmojiPickerScreenHeaderView: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.compound.bodyMD.bold())
            .foregroundColor(.compound.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct EmojiPickerScreenHeaderView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        EmojiPickerScreenHeaderView(title: "Title")
    }
}
