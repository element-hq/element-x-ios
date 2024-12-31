//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import WysiwygComposer

struct RoomScreen: View {
    @ObservedObject var roomContext: RoomScreenViewModel.Context
    @ObservedObject var timelineContext: TimelineViewModel.Context
    @ObservedObject private var composerToolbarContext: ComposerToolbarViewModel.Context
    @State private var dragOver = false
    let composerToolbar: ComposerToolbar

    init(roomViewModel: RoomScreenViewModelProtocol,
         timelineViewModel: TimelineViewModelProtocol,
         composerToolbar: ComposerToolbar) {
        roomContext = roomViewModel.context
        timelineContext = timelineViewModel.context
        self.composerToolbar = composerToolbar
        composerToolbarContext = composerToolbar.context
    }

    var body: some View {
        timeline
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .overlay(alignment: .top) {
                pinnedItemsBanner
            }
            // This can overlay on top of the pinnedItemsBanner
            .overlay(alignment: .top) {
                knockRequestsBanner
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    RoomScreenFooterView(details: roomContext.viewState.footerDetails,
                                         mediaProvider: roomContext.mediaProvider) { action in
                        roomContext.send(viewAction: .footerViewAction(action))
                    }
                    
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
                        .environmentObject(timelineContext)
                        .environment(\.timelineContext, timelineContext)
                        // Make sure the reply header honours the hideTimelineMedia setting too.
                        .environment(\.shouldAutomaticallyLoadImages, !timelineContext.viewState.hideTimelineMedia)
                }
            }
            .navigationTitle(L10n.screenRoomTitle) // Hidden but used for back button text.
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(isNavigationBarHidden)
            .toolbar { toolbar }
            .toolbarBackground(.visible, for: .navigationBar) // Fix the toolbar's background.
            .overlay { loadingIndicator }
            .alert(item: $timelineContext.alertInfo)
            .sheet(item: $timelineContext.debugInfo) { TimelineItemDebugView(info: $0) }
            .sheet(item: $timelineContext.actionMenuInfo) { info in
                let actions = TimelineItemMenuActionProvider(timelineItem: info.item,
                                                             canCurrentUserRedactSelf: timelineContext.viewState.canCurrentUserRedactSelf,
                                                             canCurrentUserRedactOthers: timelineContext.viewState.canCurrentUserRedactOthers,
                                                             canCurrentUserPin: timelineContext.viewState.canCurrentUserPin,
                                                             pinnedEventIDs: timelineContext.viewState.pinnedEventIDs,
                                                             isDM: timelineContext.viewState.isEncryptedOneToOneRoom,
                                                             isViewSourceEnabled: timelineContext.viewState.isViewSourceEnabled,
                                                             timelineKind: timelineContext.viewState.timelineKind,
                                                             emojiProvider: timelineContext.viewState.emojiProvider)
                    .makeActions()
                if let actions {
                    TimelineItemMenu(item: info.item, actions: actions)
                        .environmentObject(timelineContext)
                }
            }
            .sheet(item: $timelineContext.reactionSummaryInfo) {
                ReactionsSummaryView(reactions: $0.reactions,
                                     members: timelineContext.viewState.members,
                                     mediaProvider: timelineContext.mediaProvider,
                                     selectedReactionKey: $0.selectedKey)
                    .edgesIgnoringSafeArea([.bottom])
            }
            .sheet(item: $timelineContext.readReceiptsSummaryInfo) {
                ReadReceiptsSummaryView(orderedReadReceipts: $0.orderedReceipts)
                    .environmentObject(timelineContext)
            }
            .interactiveQuickLook(item: $timelineContext.mediaPreviewItem)
            .track(screen: .Room)
            .onDrop(of: ["public.item", "public.file-url"], isTargeted: $dragOver) { providers -> Bool in
                guard let provider = providers.first,
                      provider.isSupportedForPasteOrDrop else {
                    return false
                }
                
                timelineContext.send(viewAction: .handlePasteOrDrop(provider: provider))
                return true
            }
            .sentryTrace("\(Self.self)")
    }

    private var timeline: some View {
        TimelineView()
            .id(timelineContext.viewState.roomID)
            .environmentObject(timelineContext)
            .environment(\.focussedEventID, timelineContext.viewState.timelineState.focussedEvent?.eventID)
            .overlay(alignment: .bottomTrailing) {
                scrollToBottomButton
            }
    }
    
    @ViewBuilder
    private var pinnedItemsBanner: some View {
        Group {
            if roomContext.viewState.shouldShowPinnedEventsBanner {
                PinnedItemsBannerView(state: roomContext.viewState.pinnedEventsBannerState,
                                      onMainButtonTap: { roomContext.send(viewAction: .tappedPinnedEventsBanner) },
                                      onViewAllButtonTap: { roomContext.send(viewAction: .viewAllPins) })
                    .transition(.move(edge: .top))
            }
        }
        .animation(.elementDefault, value: roomContext.viewState.shouldShowPinnedEventsBanner)
    }
    
    @ViewBuilder
    private var knockRequestsBanner: some View {
        Group {
            if roomContext.viewState.shouldSeeKnockRequests {
                KnockRequestsBannerView(requests: roomContext.viewState.displayedKnockRequests,
                                        onDismiss: dismissKnockRequestsBanner,
                                        onAccept: roomContext.viewState.canAcceptKnocks ? acceptKnockRequest : nil,
                                        onViewAll: onViewAllKnockRequests,
                                        mediaProvider: roomContext.mediaProvider)
                    .padding(.top, 16)
                    .transition(.move(edge: .top))
            }
        }
        .animation(.elementDefault, value: roomContext.viewState.shouldSeeKnockRequests)
    }
    
    private func dismissKnockRequestsBanner() {
        roomContext.send(viewAction: .dismissKnockRequests)
    }
    
    private func acceptKnockRequest(eventID: String) {
        roomContext.send(viewAction: .acceptKnock(eventID: eventID))
    }
    
    private func onViewAllKnockRequests() {
        roomContext.send(viewAction: .viewKnockRequests)
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
    
    @ViewBuilder
    private var loadingIndicator: some View {
        if timelineContext.viewState.showLoading {
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
            RoomHeaderView(roomName: roomContext.viewState.roomTitle,
                           roomAvatar: roomContext.viewState.roomAvatar,
                           mediaProvider: roomContext.mediaProvider)
                // Using a button stops it from getting truncated in the navigation bar
                .contentShape(.rect)
                .onTapGesture {
                    roomContext.send(viewAction: .displayRoomDetails)
                }
        }
        
        if !ProcessInfo.processInfo.isiOSAppOnMac {
            ToolbarItem(placement: .primaryAction) {
                if roomContext.viewState.shouldShowCallButton {
                    callButton
                        .disabled(!roomContext.viewState.canJoinCall)
                }
            }
        }
    }
    
    @ViewBuilder
    private var callButton: some View {
        if roomContext.viewState.hasOngoingCall {
            Button {
                roomContext.send(viewAction: .displayCall)
            } label: {
                Label(L10n.actionJoin, icon: \.videoCallSolid)
                    .labelStyle(.titleAndIcon)
            }
            .buttonStyle(ElementCallButtonStyle())
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
        } else {
            Button {
                roomContext.send(viewAction: .displayCall)
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
    static let roomProxyMock = JoinedRoomProxyMock(.init(id: "stable_id",
                                                         name: "Preview room",
                                                         hasOngoingCall: true))
    static let roomViewModel = RoomScreenViewModel.mock(roomProxyMock: roomProxyMock)
    static let timelineViewModel = TimelineViewModel(roomProxy: roomProxyMock,
                                                     timelineController: MockRoomTimelineController(),
                                                     mediaProvider: MediaProviderMock(configuration: .init()),
                                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                                     voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                     appMediator: AppMediatorMock.default,
                                                     appSettings: ServiceLocator.shared.settings,
                                                     analyticsService: ServiceLocator.shared.analytics,
                                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings))

    static var previews: some View {
        NavigationStack {
            RoomScreen(roomViewModel: roomViewModel,
                       timelineViewModel: timelineViewModel,
                       composerToolbar: ComposerToolbar.mock())
        }
    }
}
