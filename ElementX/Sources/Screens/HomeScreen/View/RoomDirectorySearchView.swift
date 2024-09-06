//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomDirectorySearchView: View {
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            Label(L10n.screenRoomlistRoomDirectoryButtonTitle, icon: \.listBulleted)
        }
        .buttonStyle(.compound(.super))
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}
    
struct RoomDirectorySearchView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        RoomDirectorySearchView { }
    }
}
