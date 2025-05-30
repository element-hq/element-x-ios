//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ThreadTimelineScreen: View {
    @ObservedObject private var context: ThreadTimelineScreenViewModelType.Context
    @ObservedObject private var timelineContext: TimelineViewModelType.Context
    @ObservedObject private var composerToolbarContext: ComposerToolbarViewModelType.Context
    @State private var dragOver = false
    private let composerToolbar: ComposerToolbar
    
    init(context: ThreadTimelineScreenViewModelType.Context,
         timelineContext: TimelineViewModelType.Context,
         composerToolbar: ComposerToolbar) {
        self.context = context
        self.timelineContext = timelineContext
        self.composerToolbar = composerToolbar
        composerToolbarContext = composerToolbar.context
    }
        
    var body: some View {
        TimelineView(timelineContext: timelineContext)
            .navigationTitle("Thread")
            .navigationBarTitleDisplayMode(.inline)
            .background(.compound.bgCanvasDefault)
            .toolbarBackground(.visible, for: .navigationBar) // Fix the toolbar's background.
            .timelineMediaPreview(viewModel: $context.mediaPreviewViewModel)
            .overlay(alignment: .bottomTrailing) {
                scrollToBottomButton
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composer
                    .padding(.bottom, composerToolbarContext.composerFormattingEnabled ? 8 : 12)
                    .background {
                        if composerToolbarContext.composerFormattingEnabled {
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.compound.borderInteractiveSecondary, lineWidth: 0.5)
                                .ignoresSafeArea()
                        }
                    }
                    .padding(.top, 8)
                    .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
                    .environmentObject(timelineContext)
                    .environment(\.timelineContext, timelineContext)
                    // Make sure the reply header honours the hideTimelineMedia setting too.
                    .environment(\.shouldAutomaticallyLoadImages, !timelineContext.viewState.hideTimelineMedia)
            }
            .onDrop(of: ["public.item", "public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                guard let provider = providers.first,
                      provider.isSupportedForPasteOrDrop else {
                    return false
                }
                
                timelineContext.send(viewAction: .handlePasteOrDrop(provider: provider))
                return true
            }
    }
    
    @ViewBuilder
    private var composer: some View {
        #warning("Check permissions here too")
//        if roomContext.viewState.canSendMessage {
        composerToolbar
//        } else {
//            Text(L10n.screenRoomTimelineNoPermissionToPost)
//                .font(.compound.bodyLG)
//                .foregroundStyle(.compound.textDisabled)
//                .multilineTextAlignment(.center)
//                .padding(.vertical, 10) // Matches the MessageComposerStyleModifier
//        }
    }
    
    private var scrollToBottomButton: some View {
        Button { timelineContext.send(viewAction: .scrollToBottom) } label: {
            Image(systemName: "chevron.down")
                .font(.compound.bodyLG)
                .fontWeight(.semibold)
                .foregroundColor(.compound.iconSecondary)
                .padding(13)
                .offset(y: 1)
                .background {
                    Circle()
                        .fill(Color.compound.iconOnSolidPrimary)
                        // Intentionally using system primary colour to get white/black.
                        .shadow(color: .primary.opacity(0.33), radius: 2.0)
                }
                .padding()
        }
        .opacity(isAtBottomAndLive ? 0.0 : 1.0)
        .accessibilityHidden(isAtBottomAndLive)
        .animation(.elementDefault, value: isAtBottomAndLive)
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.scrollToBottom)
    }
    
    private var isAtBottomAndLive: Bool {
        timelineContext.isScrolledToBottom && timelineContext.viewState.timelineState.isLive
    }
}
