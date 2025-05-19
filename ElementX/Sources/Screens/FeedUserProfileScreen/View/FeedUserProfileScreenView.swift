//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct FeedUserProfileScreenView: View {
    @ObservedObject var context: FeedUserProfileScreenViewModel.Context
    @State private var scrollViewAdapter = ScrollViewAdapter()
    
    var body: some View {
        FeedUserProfileDetailsView(context: context,
                                     scrollViewAdapter: scrollViewAdapter)
        .alert(item: $context.alertInfo)
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
        .sentryTrace("\(Self.self)")
    }
}
