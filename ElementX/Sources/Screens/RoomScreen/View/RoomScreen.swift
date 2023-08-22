//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI
import WysiwygComposer

struct RoomScreen: View {
    @ObservedObject var context: RoomScreenViewModel.Context
    @State private var dragOver = false
    let composerToolbar: ComposerToolbar

    private let attachmentButtonPadding = 10.0
    @FocusState private var composerFocused: Bool
    
    var body: some View {
        timeline
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composerToolbar
                    .padding(.leading, attachmentButtonPadding)
                    .padding(.trailing, 12)
                    .padding(.top, 8)
                    .padding(.bottom)
                    .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
                    .focused($composerFocused)
                    .environmentObject(context)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarBackground(.visible, for: .navigationBar) // Fix the toolbar's background.
            .overlay { loadingIndicator }
            .alert(item: $context.alertInfo)
            .sheet(item: $context.debugInfo) { TimelineItemDebugView(info: $0) }
            .sheet(item: $context.actionMenuInfo) { info in
                context.viewState.timelineItemMenuActionProvider?(info.item.id).map { actions in
                    TimelineItemMenu(item: info.item, actions: actions)
                        .environmentObject(context)
                }
            }
            .sheet(item: $context.reactionSummaryInfo) {
                ReactionsSummaryView(reactions: $0.reactions, members: context.viewState.members, imageProvider: context.imageProvider, selectedReactionKey: $0.selectedKey)
                    .edgesIgnoringSafeArea([.bottom])
            }
            .interactiveQuickLook(item: $context.mediaPreviewItem)
            .track(screen: .room)
            .onDrop(of: ["public.item"], isTargeted: $dragOver) { providers -> Bool in
                guard let provider = providers.first,
                      provider.isSupportedForPasteOrDrop else {
                    return false
                }
                
                context.send(viewAction: .handlePasteOrDrop(provider: provider))
                return true
            }
            .confirmationDialog(item: $context.sendFailedConfirmationDialogInfo, titleVisibility: .visible) { info in
                Button(L10n.screenRoomRetrySendMenuSendAgainAction) {
                    context.send(viewAction: .retrySend(itemID: info.itemID))
                }
                Button(L10n.screenRoomRetrySendMenuRemoveAction, role: .destructive) {
                    context.send(viewAction: .cancelSend(itemID: info.itemID))
                }
            }
            .onChange(of: context.isScrolledToBottom) { isScrolledToBottom in
                if isScrolledToBottom {
                    context.send(viewAction: .scrolledToBottom)
                }
            }
            .onChange(of: context.composerFocused) { newValue in
                guard newValue != composerFocused else { return }

                composerFocused = newValue
            }
            .onChange(of: composerFocused) { newValue in
                context.composerFocused = newValue
            }
    }

    private var timeline: some View {
        timelineSwitch
            .id(context.viewState.roomID)
            .environmentObject(context)
            .environment(\.timelineStyle, context.viewState.timelineStyle)
            .environment(\.readReceiptsEnabled, context.viewState.readReceiptsEnabled)
    }

    @ViewBuilder
    private var timelineSwitch: some View {
        if context.viewState.swiftUITimelineEnabled {
            TimelineView(viewState: context.viewState.timelineViewState,
                         isScrolledToBottom: $context.isScrolledToBottom) {
                context.send(viewAction: .paginateBackwards)
            }
        } else {
            UITimelineView()
                .overlay(alignment: .bottomTrailing) {
                    scrollToBottomButton
                }
        }
    }

    private var scrollToBottomButton: some View {
        Button { context.viewState.timelineViewState.scrollToBottomPublisher.send(()) } label: {
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
        .opacity(context.isScrolledToBottom ? 0.0 : 1.0)
        .accessibilityHidden(context.isScrolledToBottom)
        .animation(.elementDefault, value: context.isScrolledToBottom)
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        if context.viewState.showLoading {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.compound.textPrimary)
                .padding(16)
                .background(.ultraThickMaterial)
                .cornerRadius(8)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        // .principal + .primaryAction works better than .navigation leading + trailing
        // as the latter disables interaction in the action button for rooms with long names
        ToolbarItem(placement: .principal) {
            RoomHeaderView(context: context)
        }
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               roomProxy: RoomProxyMock(with: .init(displayName: "Preview room")),
                                               appSettings: ServiceLocator.shared.settings,
                                               analytics: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController)

    static let wysiwygViewModel = WysiwygComposerViewModel()
    static let composerViewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel)
    static let composerToolbar = ComposerToolbar(context: composerViewModel.context,
                                                 wysiwygViewModel: wysiwygViewModel,
                                                 keyCommandHandler: { _ in false })
    
    static var previews: some View {
        NavigationStack {
            RoomScreen(context: viewModel.context, composerToolbar: composerToolbar)
        }
    }
}
