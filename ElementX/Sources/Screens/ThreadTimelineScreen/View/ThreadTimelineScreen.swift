//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ThreadTimelineScreen: View {
    @ObservedObject private var context: ThreadTimelineScreenViewModelType.Context
    @ObservedObject private var timelineContext: TimelineViewModelType.Context
    private let composerToolbar: ComposerToolbar
    
    init(context: ThreadTimelineScreenViewModelType.Context,
         timelineContext: TimelineViewModelType.Context,
         composerToolbar: ComposerToolbar) {
        self.context = context
        self.timelineContext = timelineContext
        self.composerToolbar = composerToolbar
    }
        
    var body: some View {
        TimelineView(timelineContext: timelineContext)
            .background(.compound.bgCanvasDefault)
            .toolbarRole(RoomHeaderView.toolbarRole)
            .navigationTitle(L10n.commonThread)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarBackground(.visible, for: .navigationBar) // Fix the toolbar's background.
            .timelineMediaPreview(viewModel: $context.mediaPreviewViewModel)
            .overlay(alignment: .bottomTrailing) {
                TimelineScrollToBottomButton(isVisible: isAtBottomAndLive) {
                    timelineContext.send(viewAction: .scrollToBottom)
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composer
                    .padding(.top, 8)
                    .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
                    .environmentObject(timelineContext)
                    .environment(\.timelineContext, timelineContext)
                    // Make sure the reply header honours the hideTimelineMedia setting too.
                    .environment(\.shouldAutomaticallyLoadImages, !timelineContext.viewState.hideTimelineMedia)
            }
    }
    
    @ViewBuilder
    private var composer: some View {
        if context.viewState.canSendMessage {
            composerToolbar
        } else {
            ComposerDisabledView()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        // .principal + .primaryAction works better than .navigation leading + trailing
        // as the latter disables interaction in the action button for rooms with long names
        ToolbarItem(placement: .principal) {
            RoomHeaderView(roomName: L10n.commonThread,
                           roomSubtitle: context.viewState.roomTitle,
                           roomAvatar: context.viewState.roomAvatar,
                           dmRecipientVerificationState: context.viewState.dmRecipientVerificationState,
                           roomHistorySharingState: context.viewState.roomHistorySharingState,
                           mediaProvider: context.mediaProvider) {
                // There is no action but the iOS 26 designs have it looking like a button.
            }
        }
    }
    
    private var isAtBottomAndLive: Bool {
        timelineContext.isScrolledToBottom && timelineContext.viewState.timelineState.isLive
    }
}
