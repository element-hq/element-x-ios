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

    init(context: RoomScreenViewModelType.Context,
         timelineContext: TimelineViewModelType.Context,
         composerToolbar: ComposerToolbar) {
        self.context = context
        self.timelineContext = timelineContext
        self.composerToolbar = composerToolbar
    }

    var body: some View {
        TimelineView(timelineContext: timelineContext)
            .overlay(alignment: .bottomTrailing) {
                TimelineScrollToBottomButton(isVisible: isAtBottomAndLive) {
                    timelineContext.send(viewAction: .scrollToBottom)
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.scrollToBottom)
            }
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .topBanners([
                TopBannerItem(pinnedItemsBanner, isVisible: context.viewState.shouldShowPinnedEventsBanner && !isVoiceOverEnabled),
                // This can overlay on top of the pinnedItemsBanner
                TopBannerItem(knockRequestsBanner, isVisible: context.viewState.shouldSeeKnockRequests)
            ], footer: dateBadge)
            .safeAreaInset(edge: .top) {
                // When VoiceOver is enabled, the table view isn't reversed and the scroll gestures
                // don't trigger meaning the banner never hides itself and so the .overlay layout
                // above permanently obscures the top of the timeline. So whenever VoiceOver is
                // enabled we use a safe area inset to vertically stack it above the timeline.
                if context.viewState.shouldShowPinnedEventsBanner, isVoiceOverEnabled {
                    pinnedItemsBanner
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
            .track(screen: .Room)
            .sentryTrace("\(Self.self)")
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
            FloatingDateBadge(dateText: timelineContext.floatingDateText)
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
    
    private var isAtBottomAndLive: Bool {
        timelineContext.isScrolledToBottom && timelineContext.viewState.timelineState.isLive
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
                callControls
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
    }
    
    @ToolbarContentBuilder
    private var callControls: some ToolbarContent {
        if context.viewState.hasOngoingCall {
            // XXX: Future work: get the active call
            // intent to switch between voice and audio
            ToolbarItem(placement: .primaryAction) {
                JoinCallButton {
                    context.send(viewAction: .displayCall(isVoiceCall: false))
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.joinCall)
                .disabled(!context.viewState.canJoinCall)
            }
        } else {
            if context.viewState.isDirectOneToOneRoom {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        context.send(viewAction: .displayCall(isVoiceCall: true))
                    } label: {
                        CompoundIcon(\.voiceCallSolid)
                    }
                    .accessibilityLabel(L10n.a11yStartVoiceCall)
                    .accessibilityIdentifier(A11yIdentifiers.roomScreen.startVoiceCall)
                    .disabled(!context.viewState.canJoinCall)
                }
            }
            ToolbarItem(placement: .primaryAction) {
                Button {
                    context.send(viewAction: .displayCall(isVoiceCall: false))
                } label: {
                    CompoundIcon(\.videoCallSolid)
                }
                .accessibilityLabel(L10n.a11yStartCall)
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.startCall)
                .disabled(!context.viewState.canJoinCall)
            }
        }
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModels = makeViewModels()
    static let viewModelNoActiveCall = makeViewModels(hasOngoingCall: false, isDirect: true)
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
        
        ElementNavigationStack {
            RoomScreen(context: viewModelNoActiveCall.room.context,
                       timelineContext: viewModelNoActiveCall.timeline.context,
                       composerToolbar: ComposerToolbar(context: composerViewModel.context))
        }
        .previewDisplayName("DM - No active call")
    }
    
    static func makeViewModels(canSendMessage: Bool = true, hasSuccessor: Bool = false, hasOngoingCall: Bool = true, isDirect: Bool = false) -> ViewModels {
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "stable_id",
                                                      successor: hasSuccessor ? .init(roomId: UUID().uuidString, reason: nil) : nil,
                                                      powerLevelsConfiguration: .init(canUserSendMessage: canSendMessage)))
        
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob]
        
        let configuration = JoinedRoomProxyMockConfiguration(id: roomProxyMock.id,
                                                             name: "Preview room",
                                                             isDirect: isDirect,
                                                             hasOngoingCall: hasOngoingCall,
                                                             members: mockedMembers)
      
        let info = RoomInfoProxyMock(configuration)
        roomProxyMock.infoPublisher = CurrentValueSubject(info).asCurrentValuePublisher()
        
        let roomViewModel = RoomScreenViewModel.mock(roomProxyMock: roomProxyMock)
        let timelineViewModel = TimelineViewModel(roomProxy: roomProxyMock,
                                                  timelineController: MockTimelineController(),
                                                  userSession: UserSessionMock(.init()),
                                                  mediaPlayerProvider: MediaPlayerProviderMock(),
                                                  userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                  appMediator: AppMediatorMock.default,
                                                  appSettings: ServiceLocator.shared.settings,
                                                  analyticsService: ServiceLocator.shared.analytics,
                                                  emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                                  linkMetadataProvider: LinkMetadataProvider(),
                                                  timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        
        return .init(room: roomViewModel, timeline: timelineViewModel)
    }
    
    struct ViewModels {
        let room: RoomScreenViewModelProtocol
        let timeline: TimelineViewModelProtocol
    }
}
