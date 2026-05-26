//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI
import WysiwygComposer

struct RoomScreen: View {
    @ObservedObject private var context: RoomScreenViewModelType.Context
    @ObservedObject private var timelineContext: TimelineViewModelType.Context
    let composerToolbar: ComposerToolbar
    @Environment(\.accessibilityVoiceOverEnabled) private var isVoiceOverEnabled

    enum MarkAsReadSource {
        case up
        case down
    }

    /// Which scroll button (if any) currently has the "Mark as read" pill displayed alongside it.
    /// Set when the user long-presses one of the scroll buttons; the pill anchors to that button.
    @State private var markAsReadSource: MarkAsReadSource?

    init(context: RoomScreenViewModelType.Context,
         timelineContext: TimelineViewModelType.Context,
         composerToolbar: ComposerToolbar) {
        self.context = context
        self.timelineContext = timelineContext
        self.composerToolbar = composerToolbar
    }

    var body: some View {
        TimelineView(timelineContext: timelineContext)
            .overlay {
                // Sits below the bottom-trailing overlay in z-order, so taps on the pill or
                // buttons still go to them; taps anywhere else dismiss the pill.
                if markAsReadSource != nil {
                    Color.clear
                        .contentShape(Rectangle())
                        .onTapGesture { dismissMarkAsReadPill() }
                }
            }
            .overlay(alignment: .bottomTrailing) {
                VStack(alignment: .trailing, spacing: 16) {
                    HStack(spacing: 8) {
                        if markAsReadSource == .up {
                            markAsReadPill
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                        jumpToReadMarkerButton
                    }
                    HStack(spacing: 8) {
                        if markAsReadSource == .down {
                            markAsReadPill
                                .transition(.move(edge: .trailing).combined(with: .opacity))
                        }
                        TimelineScrollButton(isHidden: !timelineContext.viewState.shouldShowScrollToBottomButton,
                                             showsBadge: scrollToBottomShowsBadge,
                                             onLongPress: scrollToBottomShowsBadge ? { revealMarkAsReadPill(source: .down) } : nil) {
                            dismissMarkAsReadPill()
                            timelineContext.send(viewAction: .scrollToBottom)
                        }
                        .accessibilityIdentifier(A11yIdentifiers.roomScreen.scrollToBottom)
                    }
                }
                .padding()
                .animation(.elementDefault, value: markAsReadSource)
            }
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .topBanners([
                TopBannerLayer(verticalBanners: [
                    TopBannerItem(pinnedItemsBanner, isVisible: context.viewState.shouldShowPinnedEventsBanner && !isVoiceOverEnabled),
                    TopBannerItem(liveLocationBanner, isVisible: context.viewState.isSharingLiveLocation && !isVoiceOverEnabled)
                ]),
                // This can overlay on top of the stacked banners
                TopBannerLayer(knockRequestsBanner, isVisible: context.viewState.shouldSeeKnockRequests)
            ], footer: dateBadge)
            .safeAreaInset(edge: .top) {
                // When VoiceOver is enabled, the table view isn't reversed and the scroll gestures
                // don't trigger meaning the banner never hides itself and so the .overlay layout
                // above permanently obscures the top of the timeline. So whenever VoiceOver is
                // enabled we use a safe area inset to vertically stack it above the timeline.
                if context.viewState.shouldShowPinnedEventsBanner || context.viewState.isSharingLiveLocation, isVoiceOverEnabled {
                    VStack(spacing: 0) {
                        if context.viewState.shouldShowPinnedEventsBanner {
                            pinnedItemsBanner
                        }
                        if context.viewState.isSharingLiveLocation {
                            liveLocationBanner
                        }
                    }
                }
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                VStack(spacing: 0) {
                    RoomScreenFooterView(details: context.viewState.footerDetails,
                                         mediaProvider: context.mediaProvider) { action in
                        context.send(viewAction: .footerViewAction(action))
                    }
                    
                    composer
                        .padding(.top, 8)
                        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
                        .environmentObject(timelineContext)
                        .environment(\.timelineContext, timelineContext)
                        // Make sure the reply header honours the hideTimelineMedia setting too.
                        .environment(\.shouldAutomaticallyLoadImages, !timelineContext.viewState.hideTimelineMedia)
                }
            }
            .toolbarRole(RoomHeaderView.toolbarRole)
            .navigationTitle(L10n.screenRoomTitle) // Hidden but used for back button text.
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarBackground(.visible, for: .navigationBar) // Fix the toolbar's background.
            .overlay { loadingIndicator }
            .alert(item: $context.alertInfo)
            .timelineMediaPreview(viewModel: $context.mediaPreviewViewModel)
            .onChange(of: pillSourceButtonIsVisible) { _, isVisible in
                if !isVisible { dismissMarkAsReadPill() }
            }
            .track(screen: .Room)
            .sentryTrace("\(Self.self)")
    }
    
    private var liveLocationBanner: some View {
        LiveLocationSharingBannerView {
            context.send(viewAction: .tappedOpenLiveLocation)
        } onStop: {
            context.send(viewAction: .tappedStopLiveLocation)
        }
    }
    
    private var pinnedItemsBanner: some View {
        PinnedItemsBannerView(state: context.viewState.pinnedEventsBannerState,
                              onMainButtonTap: { context.send(viewAction: .tappedPinnedEventsBanner) },
                              onViewAllButtonTap: { context.send(viewAction: .viewAllPins) })
    }
    
    private var knockRequestsBanner: some View {
        KnockRequestsBannerView(requests: context.viewState.displayedKnockRequests,
                                onDismiss: dismissKnockRequestsBanner,
                                onAccept: context.viewState.canAcceptKnocks ? acceptKnockRequest : nil,
                                onViewAll: onViewAllKnockRequests,
                                mediaProvider: context.mediaProvider)
            .padding(.top, 16)
    }
    
    @ViewBuilder
    private var dateBadge: some View {
        if !isVoiceOverEnabled {
            FloatingDateBadge(dateText: timelineContext.floatingDate?.formattedDateSeparator()) {
                timelineContext.send(viewAction: .scrollToFirstItemForCurrentDate)
            }
        }
    }
    
    private func dismissKnockRequestsBanner() {
        context.send(viewAction: .dismissKnockRequests)
    }
    
    private func acceptKnockRequest(eventID: String) {
        context.send(viewAction: .acceptKnock(eventID: eventID))
    }
    
    private func onViewAllKnockRequests() {
        context.send(viewAction: .viewKnockRequests)
    }
    
    @ViewBuilder
    private var jumpToReadMarkerButton: some View {
        if timelineContext.viewState.shouldShowJumpToReadMarker {
            TimelineScrollButton(direction: .up,
                                 showsBadge: true) {
                revealMarkAsReadPill(source: .up)
            } callback: {
                dismissMarkAsReadPill()
                timelineContext.send(viewAction: .scrollToReadMarker)
            }
        }
    }

    private var markAsReadPill: some View {
        Button {
            timelineContext.send(viewAction: .markAllAsRead)
            dismissMarkAsReadPill()
        } label: {
            markAsReadPillLabel
        }
    }

    @ViewBuilder
    private var markAsReadPillLabel: some View {
        // Font scales with Dynamic Type via the Compound token; padding is a fixed point value
        // so the pill grows with the text instead of growing twice over.
        let label = Label {
            Text(L10n.screenRoomlistMarkAsRead)
        } icon: {
            CompoundIcon(\.markAsRead, size: .medium, relativeTo: .compound.bodyLG)
        }
        .font(.compound.bodyLG)
        .foregroundStyle(.compound.textPrimary)
        .padding(.horizontal, 20)
        .padding(.vertical, 20)
        if #available(iOS 26, *) {
            label.glassEffect(.regular.interactive(), in: Capsule())
        } else {
            label.background(.regularMaterial, in: Capsule())
        }
    }

    private func revealMarkAsReadPill(source: MarkAsReadSource) {
        markAsReadSource = source
    }

    private func dismissMarkAsReadPill() {
        markAsReadSource = nil
    }

    /// Whether the scroll button that the pill is anchored to is still being rendered.
    /// Used to dismiss an orphaned pill when the source button gets hidden — without
    /// this, the pill can render alongside an invisible button. Returns `true` when no
    /// pill is shown so the `onChange` doesn't fire spuriously when the source clears.
    private var pillSourceButtonIsVisible: Bool {
        switch markAsReadSource {
        case .up: timelineContext.viewState.shouldShowJumpToReadMarker
        case .down: timelineContext.viewState.shouldShowScrollToBottomButton
        case .none: true
        }
    }

    /// Hide the new-messages dot when the jump-to-read-marker feature is disabled.
    private var scrollToBottomShowsBadge: Bool {
        timelineContext.viewState.jumpToReadMarkerEnabled
            && timelineContext.viewState.bindings.hasNewMessagesAtBottom
    }

    @ViewBuilder
    private var composer: some View {
        if context.viewState.hasSuccessor {
            tombstonedDialogue
        } else if context.viewState.canSendMessage, !ProcessInfo.isRunningAccessibilityTests {
            // We are not sure why but when wrapped in the room screen the composer toolbar breaks the accessibility tests
            composerToolbar
        } else {
            ComposerDisabledView()
        }
    }
    
    private var tombstonedDialogue: some View {
        VStack(spacing: 16) {
            Text(L10n.screenRoomTimelineTombstonedRoomMessage)
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textPrimary)
            
            Button {
                context.send(viewAction: .displaySuccessorRoom)
            } label: {
                Text(L10n.screenRoomTimelineTombstonedRoomAction)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.compound(.primary, size: .medium))
        }
        .padding(.top, 16)
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
        .highlight(gradient: .compound.info, borderColor: .compound.borderInfoSubtle)
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
            RoomHeaderView(roomName: context.viewState.roomTitle,
                           roomAvatar: context.viewState.roomAvatar,
                           dmRecipientVerificationState: context.viewState.dmRecipientVerificationState,
                           roomHistorySharingState: context.viewState.roomHistorySharingState,
                           mediaProvider: context.mediaProvider) {
                context.send(viewAction: .displayRoomDetails)
            }
        }
        
        if !ProcessInfo.processInfo.isiOSAppOnMac {
            if context.viewState.shouldShowCallButton {
                RoomCallControlsToolbar(viewState: context.viewState) { isVoiceCall in
                    context.send(viewAction: .displayCall(isVoiceCall: isVoiceCall))
                }
            }
        }
        
        if context.viewState.roomThreadListEnabled {
            if #available(iOS 26, *) {
                ToolbarSpacer(.fixed, placement: .primaryAction)
            }
            
            ToolbarItem(placement: .primaryAction) {
                Button {
                    context.send(viewAction: .displayThreadList)
                } label: {
                    CompoundIcon(\.threads)
                }
            }
        }

        ToolbarItem(placement: .primaryAction) {
            Button {
                context.send(viewAction: .displayMessageSearch)
            } label: {
                CompoundIcon(\.search)
            }
            .accessibilityLabel(L10n.actionSearch)
        }
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModels = makeViewModels()
    static let readOnlyViewModels = makeViewModels(canSendMessage: false)
    static let tombstonedViewModels = makeViewModels(hasSuccessor: true)
    static let composerViewModel = ComposerToolbarViewModel.mock()

    static var previews: some View {
        ElementNavigationStack {
            RoomScreen(context: viewModels.room.context,
                       timelineContext: viewModels.timeline.context,
                       composerToolbar: ComposerToolbar(context: composerViewModel.context))
        }
        .previewDisplayName("Normal")
        
        ElementNavigationStack {
            RoomScreen(context: readOnlyViewModels.room.context,
                       timelineContext: readOnlyViewModels.timeline.context,
                       composerToolbar: ComposerToolbar(context: composerViewModel.context))
        }
        .previewDisplayName("Read-only")
        .snapshotPreferences(expect: readOnlyViewModels.room.context.$viewState.map { !$0.canSendMessage })
        
        ElementNavigationStack {
            RoomScreen(context: tombstonedViewModels.room.context,
                       timelineContext: tombstonedViewModels.timeline.context,
                       composerToolbar: ComposerToolbar(context: composerViewModel.context))
        }
        .previewDisplayName("Tombstoned")
        .snapshotPreferences(expect: tombstonedViewModels.room.context.$viewState.map(\.hasSuccessor))
    }
    
    static func makeViewModels(canSendMessage: Bool = true, hasSuccessor: Bool = false) -> ViewModels {
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "stable_id",
                                                      name: "Preview room",
                                                      hasOngoingCall: true,
                                                      successor: hasSuccessor ? .init(roomId: UUID().uuidString, reason: nil) : nil,
                                                      powerLevelsConfiguration: .init(canUserSendMessage: canSendMessage)))
        let roomViewModel = RoomScreenViewModel.mock(roomProxyMock: roomProxyMock)

        let appSettings = AppSettings.volatile()
        let timelineViewModel = TimelineViewModel(roomProxy: roomProxyMock,
                                                  timelineController: MockTimelineController(),
                                                  userSession: UserSessionMock(.init()),
                                                  mediaPlayerProvider: MediaPlayerProviderMock(),
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appMediator: AppMediatorMock(.init()),
                                                  appSettings: appSettings,
                                                  analyticsService: AnalyticsServiceMock(.init()),
                                                  emojiProvider: EmojiProvider(appSettings: appSettings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        
        return .init(room: roomViewModel, timeline: timelineViewModel)
    }
    
    struct ViewModels {
        let room: RoomScreenViewModelProtocol
        let timeline: TimelineViewModelProtocol
    }
}
