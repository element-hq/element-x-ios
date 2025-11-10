//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias PinnedEventsTimelineScreenViewModelType = StateStoreViewModel<PinnedEventsTimelineScreenViewState, PinnedEventsTimelineScreenViewAction>

class PinnedEventsTimelineScreenViewModel: PinnedEventsTimelineScreenViewModelType, PinnedEventsTimelineScreenViewModelProtocol {
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let appSettings: AppSettings
    private let analyticsService: AnalyticsService
    
    private let actionsSubject: PassthroughSubject<PinnedEventsTimelineScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<PinnedEventsTimelineScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appSettings: AppSettings,
         analyticsService: AnalyticsService) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        self.appSettings = appSettings
        self.analyticsService = analyticsService
        super.init(initialViewState: PinnedEventsTimelineScreenViewState())
    }
    
    // MARK: - Public
    
    override func process(viewAction: PinnedEventsTimelineScreenViewAction) {
        MXLog.info("View model: received view action: \(viewAction)")
        
        switch viewAction {
        case .close:
            analyticsService.trackInteraction(name: .PinnedMessageBannerCloseListButton)
            actionsSubject.send(.dismiss)
        }
    }
    
    func stop() {
        // Work around QLPreviewController dismissal issues, see the InteractiveQuickLookModifier.
        state.bindings.mediaPreviewViewModel = nil
    }
    
    func displayMediaPreview(_ mediaPreviewViewModel: TimelineMediaPreviewViewModel) {
        mediaPreviewViewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .displayMessageForwarding(let forwardingItem):
                state.bindings.mediaPreviewViewModel = nil
                // We need a small delay because we need to wait for the media preview to be fully dismissed.
                DispatchQueue.main.asyncAfter(deadline: .now() + TimelineMediaPreviewViewModel.displayMessageForwardingDelay) {
                    self.actionsSubject.send(.displayMessageForwarding(forwardingItem))
                }
            case .viewInRoomTimeline(let itemID):
                guard let eventID = itemID.eventID else {
                    return
                }
                Task { await self.viewInRoomTimeline(eventID: eventID) }
            case .dismiss:
                state.bindings.mediaPreviewViewModel = nil
            }
        }
        .store(in: &cancellables)
        
        state.bindings.mediaPreviewViewModel = mediaPreviewViewModel
    }
    
    private func viewInRoomTimeline(eventID: String) async {
        switch await roomProxy.loadOrFetchEventDetails(for: eventID) {
        case .success(let event):
            let threadRootEventID: String? = if appSettings.threadsEnabled {
                event.threadRootEventId()
            } else {
                nil
            }
            actionsSubject.send(.viewInRoomTimeline(eventID: eventID, threadRootEventID: threadRootEventID))
        case .failure:
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
        }
    }
}
