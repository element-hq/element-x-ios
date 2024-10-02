//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
}
