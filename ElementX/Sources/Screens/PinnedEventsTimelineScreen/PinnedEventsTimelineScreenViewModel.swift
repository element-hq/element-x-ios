//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias PinnedEventsTimelineScreenViewModelType = StateStoreViewModel<PinnedEventsTimelineScreenViewState, PinnedEventsTimelineScreenViewAction>

class PinnedEventsTimelineScreenViewModel: PinnedEventsTimelineScreenViewModelType, PinnedEventsTimelineScreenViewModelProtocol {
    private let analyticsService: AnalyticsService
    
    private let actionsSubject: PassthroughSubject<PinnedEventsTimelineScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<PinnedEventsTimelineScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(analyticsService: AnalyticsService) {
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
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.actionsSubject.send(.displayMessageForwarding(forwardingItem))
                }
            case .viewInRoomTimeline(let itemID):
                actionsSubject.send(.viewInRoomTimeline(itemID: itemID))
            case .dismiss:
                state.bindings.mediaPreviewViewModel = nil
            }
        }
        .store(in: &cancellables)
        
        state.bindings.mediaPreviewViewModel = mediaPreviewViewModel
    }
}
