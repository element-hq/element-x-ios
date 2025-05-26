//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ThreadTimelineScreen: View {
    @ObservedObject var context: ThreadTimelineScreenViewModel.Context
    @ObservedObject var timelineContext: TimelineViewModel.Context
        
    var body: some View {
        TimelineView(timelineContext: timelineContext)
            .navigationTitle("Thread")
            .navigationBarTitleDisplayMode(.inline)
            .background(.compound.bgCanvasDefault)
            .interactiveDismissDisabled()
            .timelineMediaPreview(viewModel: $context.mediaPreviewViewModel)
    }
}
