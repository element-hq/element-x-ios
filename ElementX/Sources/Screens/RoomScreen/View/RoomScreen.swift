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
        TimelineView(timelineContext: timelineContext)
            .overlay(alignment: .bottomTrailing) {
                scrollToBottomButton
            }
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
            }
            .navigationTitle(L10n.screenRoomTitle) // Hidden but used for back button text.
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarHidden(isNavigationBarHidden)
            .toolbar { toolbar }
            .toolbarBackground(.visible, for: .navigationBar) // Fix the toolbar's background.
            .overlay { loadingIndicator }
            .timelineMediaPreview(viewModel: $roomContext.mediaPreviewViewModel)
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
    private var composer: some View {
        if roomContext.viewState.hasSuccessor {
            tombstonedDialogue
        } else if roomContext.viewState.canSendMessage {
            composerToolbar
        } else {
            Text(L10n.screenRoomTimelineNoPermissionToPost)
                .font(.compound.bodyLG)
                .foregroundStyle(.compound.textDisabled)
                .multilineTextAlignment(.center)
                .padding(.vertical, 10) // Matches the MessageComposerStyleModifier
        }
    }
    
    private var tombstonedDialogue: some View {
        VStack(spacing: 16) {
            Text(L10n.screenRoomTimelineTombstonedRoomMessage)
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textPrimary)
            
            Button {
                roomContext.send(viewAction: .displaySuccessorRoom)
            } label: {
                Text(L10n.screenRoomTimelineTombstonedRoomAction)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compound(.primary, size: .medium))
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 8)
        .highlight(borderColor: .compound.borderInfoSubtle,
                   primaryColor: .compound.bgInfoSubtle,
                   secondaryColor: .compound.bgCanvasDefault)
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
                           dmRecipientVerificationState: roomContext.viewState.dmRecipientVerificationState,
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
            .accessibilityLabel(L10n.a11yJoinCall)
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
        } else {
            Button {
                roomContext.send(viewAction: .displayCall)
            } label: {
                CompoundIcon(\.videoCallSolid)
            }
            .accessibilityLabel(L10n.a11yStartCall)
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
        }
    }
    
    private var isNavigationBarHidden: Bool {
        composerToolbarContext.composerFormattingEnabled && composerToolbarContext.composerExpanded && UIDevice.current.userInterfaceIdiom == .pad
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModels = makeViewModels()
    static let readOnlyViewModels = makeViewModels(canSendMessage: false)
    static let tombstonedViewModels = makeViewModels(hasSuccessor: true)

    static var previews: some View {
        NavigationStack {
            RoomScreen(roomViewModel: viewModels.room,
                       timelineViewModel: viewModels.timeline,
                       composerToolbar: ComposerToolbar.mock())
        }
        .previewDisplayName("Normal")
        
        NavigationStack {
            RoomScreen(roomViewModel: readOnlyViewModels.room,
                       timelineViewModel: readOnlyViewModels.timeline,
                       composerToolbar: ComposerToolbar.mock())
        }
        .previewDisplayName("Read-only")
        .snapshotPreferences(expect: readOnlyViewModels.room.context.$viewState.map { !$0.canSendMessage })
        
        NavigationStack {
            RoomScreen(roomViewModel: tombstonedViewModels.room,
                       timelineViewModel: tombstonedViewModels.timeline,
                       composerToolbar: ComposerToolbar.mock())
        }
        .previewDisplayName("Tombstoned")
        .snapshotPreferences(expect: tombstonedViewModels.room.context.$viewState.map(\.hasSuccessor))
    }
    
    static func makeViewModels(canSendMessage: Bool = true, hasSuccessor: Bool = false) -> ViewModels {
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "stable_id",
                                                      name: "Preview room",
                                                      hasOngoingCall: true,
                                                      canUserSendMessage: canSendMessage,
                                                      successor: hasSuccessor ? .init(roomId: UUID().uuidString, reason: nil) : nil))
        let roomViewModel = RoomScreenViewModel.mock(roomProxyMock: roomProxyMock)
        let timelineViewModel = TimelineViewModel(roomProxy: roomProxyMock,
                                                  timelineController: MockTimelineController(),
                                                  mediaProvider: MediaProviderMock(configuration: .init()),
                                                  mediaPlayerProvider: MediaPlayerProviderMock(),
                                                  voiceMessageMediaManager: VoiceMessageMediaManagerMock(),
                                                  userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                  appMediator: AppMediatorMock.default,
                                                  appSettings: ServiceLocator.shared.settings,
                                                  analyticsService: ServiceLocator.shared.analytics,
                                                  emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                  timelineControllerFactory: TimelineControllerFactoryMock(.init()),
                                                  clientProxy: ClientProxyMock(.init()))
        
        return .init(room: roomViewModel, timeline: timelineViewModel)
    }
    
    struct ViewModels {
        let room: RoomScreenViewModelProtocol
        let timeline: TimelineViewModelProtocol
    }
}
