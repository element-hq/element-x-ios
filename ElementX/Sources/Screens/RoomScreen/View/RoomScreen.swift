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

import Compound
import SwiftUI
import WysiwygComposer

struct RoomScreen: View {
    @ObservedObject var context: RoomScreenViewModel.Context
    @ObservedObject private var composerToolbarContext: ComposerToolbarViewModel.Context
    @State private var dragOver = false
    let composerToolbar: ComposerToolbar

    init(context: RoomScreenViewModel.Context, composerToolbar: ComposerToolbar) {
        self.context = context
        self.composerToolbar = composerToolbar
        composerToolbarContext = composerToolbar.context
    }

    var body: some View {
        timeline
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .safeAreaInset(edge: .bottom, spacing: 0) {
                composerToolbar
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
                    .environmentObject(context)
                    .environment(\.roomContext, context)
            }
            .overlay(alignment: .top) {
                Group {
                    if context.viewState.shouldShowPinnedEventsBanner {
                        pinnedItemsBanner
                    }
                }
                .animation(.elementDefault, value: context.viewState.shouldShowPinnedEventsBanner)
            }
            .navigationTitle(L10n.screenRoomTitle) // Hidden but used for back button text.
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(isNavigationBarHidden)
            .toolbar { toolbar }
            .toolbarBackground(.visible, for: .navigationBar) // Fix the toolbar's background.
            .overlay { loadingIndicator }
            .alert(item: $context.alertInfo)
            .sheet(item: $context.debugInfo) { TimelineItemDebugView(info: $0) }
            .sheet(item: $context.actionMenuInfo) { info in
                let actions = TimelineItemMenuActionProvider(timelineItem: info.item,
                                                             canCurrentUserRedactSelf: context.viewState.canCurrentUserRedactSelf,
                                                             canCurrentUserRedactOthers: context.viewState.canCurrentUserRedactOthers,
                                                             canCurrentUserPin: context.viewState.canCurrentUserPin,
                                                             pinnedEventIDs: context.viewState.pinnedEventIDs,
                                                             isDM: context.viewState.isEncryptedOneToOneRoom,
                                                             isViewSourceEnabled: context.viewState.isViewSourceEnabled).makeActions()
                if let actions {
                    TimelineItemMenu(item: info.item, actions: actions)
                        .environmentObject(context)
                }
            }
            .sheet(item: $context.reactionSummaryInfo) {
                ReactionsSummaryView(reactions: $0.reactions, members: context.viewState.members, imageProvider: context.imageProvider, selectedReactionKey: $0.selectedKey)
                    .edgesIgnoringSafeArea([.bottom])
            }
            .sheet(item: $context.readReceiptsSummaryInfo) {
                ReadReceiptsSummaryView(orderedReadReceipts: $0.orderedReceipts)
                    .environmentObject(context)
            }
            .interactiveQuickLook(item: $context.mediaPreviewItem)
            .track(screen: .Room)
            .onDrop(of: ["public.item", "public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                guard let provider = providers.first,
                      provider.isSupportedForPasteOrDrop else {
                    return false
                }
                
                context.send(viewAction: .handlePasteOrDrop(provider: provider))
                return true
            }
            .sentryTrace("\(Self.self)")
    }

    private var timeline: some View {
        TimelineView()
            .id(context.viewState.roomID)
            .environmentObject(context)
            .environment(\.focussedEventID, context.viewState.timelineViewState.focussedEvent?.eventID)
            .overlay(alignment: .bottomTrailing) {
                scrollToBottomButton
            }
    }
    
    private var pinnedItemsBanner: some View {
        PinnedItemsBannerView(state: context.viewState.pinnedEventsBannerState,
                              onMainButtonTap: { context.send(viewAction: .tappedPinnedEventsBanner) },
                              onViewAllButtonTap: { context.send(viewAction: .viewAllPins) })
            .transition(.move(edge: .top))
    }
    
    private var scrollToBottomButton: some View {
        Button { context.send(viewAction: .scrollToBottom) } label: {
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
        context.isScrolledToBottom && context.viewState.timelineViewState.isLive
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
            RoomHeaderView(roomName: context.viewState.roomTitle,
                           roomAvatar: context.viewState.roomAvatar,
                           imageProvider: context.imageProvider)
                // Using a button stops it from getting truncated in the navigation bar
                .contentShape(.rect)
                .onTapGesture {
                    context.send(viewAction: .displayRoomDetails)
                }
        }
        
        if !ProcessInfo.processInfo.isiOSAppOnMac {
            ToolbarItem(placement: .primaryAction) {
                callButton
                    .disabled(context.viewState.canJoinCall == false)
            }
        }
    }
    
    @ViewBuilder
    private var callButton: some View {
        if context.viewState.hasOngoingCall {
            Button {
                context.send(viewAction: .displayCall)
            } label: {
                Label(L10n.actionJoin, icon: \.videoCallSolid)
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(ElementCallButtonStyle())
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
        } else {
            Button {
                context.send(viewAction: .displayCall)
            } label: {
                CompoundIcon(\.videoCallSolid)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
        }
    }
    
    private var isNavigationBarHidden: Bool {
        composerToolbarContext.composerFormattingEnabled && composerToolbarContext.composerExpanded && UIDevice.current.userInterfaceIdiom == .pad
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomScreenViewModel(roomProxy: RoomProxyMock(.init(id: "stable_id",
                                                                              name: "Preview room",
                                                                              hasOngoingCall: true)),
                                               timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               mediaPlayerProvider: MediaPlayerProviderMock(),
                                               voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings,
                                               analyticsService: ServiceLocator.shared.analytics)

    static var previews: some View {
        NavigationStack {
            RoomScreen(context: viewModel.context, composerToolbar: ComposerToolbar.mock())
        }
    }
}
