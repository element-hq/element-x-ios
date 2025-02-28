//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct FeedDetailsScreen: View {
    @ObservedObject var context: FeedDetailsScreenViewModel.Context
    let isRefreshable: Bool
    
    @State private var scrollViewAdapter = ScrollViewAdapter()
    
    var body: some View {
        FeedDetailsContent(context: context, isRefreshable: isRefreshable,
                           scrollViewAdapter: scrollViewAdapter)
        .alert(item: $context.alertInfo)
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
        .navigationTitle("Post")
        .navigationBarTitleDisplayMode(.inline)
        .sentryTrace("\(Self.self)")
    }
}
