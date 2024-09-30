//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension Section where Parent == Color, Content == EmptyView, Footer == EmptyView {
    // An empty section whose purpose is to keep Form's background color when there is no content into it.
    static var empty: some View {
        Section {
            EmptyView()
        } header: {
            Color.clear
        }
    }
}
