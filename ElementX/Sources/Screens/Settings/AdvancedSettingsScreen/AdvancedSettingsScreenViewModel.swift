//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias AdvancedSettingsScreenViewModelType = StateStoreViewModelV2<AdvancedSettingsScreenViewState, AdvancedSettingsScreenViewAction>

class AdvancedSettingsScreenViewModel: AdvancedSettingsScreenViewModelType, AdvancedSettingsScreenViewModelProtocol {
    private let analytics: AnalyticsService
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var timelineMediaVisibilityTask: Task<Void, Never>?
    private var hideInviteAvatarsTask: Task<Void, Never>?
    
    init(advancedSettings: AdvancedSettingsProtocol,
         analytics: AnalyticsService,
         clientProxy: ClientProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.analytics = analytics
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        let state = AdvancedSettingsScreenViewState(timelineMediaVisibility: clientProxy.timelineMediaVisibilityPublisher.value,
                                                    hideInviteAvatars: clientProxy.hideInviteAvatarsPublisher.value,
                                                    bindings: .init(advancedSettings: advancedSettings))
        super.init(initialViewState: state)
        
        clientProxy.timelineMediaVisibilityPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.timelineMediaVisibility, on: self)
            .store(in: &cancellables)
        
        clientProxy.hideInviteAvatarsPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.hideInviteAvatars, on: self)
            .store(in: &cancellables)
    }
    
    override func process(viewAction: AdvancedSettingsScreenViewAction) {
        switch viewAction {
        case .optimizeMediaUploadsChanged:
            // Note: Using a view action here as sinking the AppSettings publisher tracks the initial value.
            analytics.trackInteraction(name: state.bindings.optimizeMediaUploads ? .MobileSettingsOptimizeMediaUploadsEnabled : .MobileSettingsOptimizeMediaUploadsDisabled)
        case let .updateHideInviteAvatars(value):
            hideInviteAvatarsTask = Task { [weak self] in await self?.updateHideInviteAvatars(value) }
        case let .updateTimelineMediaVisibility(value):
            timelineMediaVisibilityTask = Task { [weak self] in await self?.updateTimelineMediaVisibility(value) }
        }
    }
    
    private func updateTimelineMediaVisibility(_ value: TimelineMediaVisibility) async {
        defer {
            timelineMediaVisibilityTask = nil
            state.isWaitingTimelineMediaVisibility = false
        }
        
        let previousState = state.timelineMediaVisibility
        state.isWaitingTimelineMediaVisibility = true
        state.timelineMediaVisibility = value
        // If the other value is updating wait also for it to finish
        await hideInviteAvatarsTask?.value
        
        switch await clientProxy.setTimelineMediaVisibility(value) {
        case .success:
            break
        case .failure:
            state.timelineMediaVisibility = previousState
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
        }
    }
    
    private func updateHideInviteAvatars(_ value: Bool) async {
        defer {
            hideInviteAvatarsTask = nil
            state.isWaitingHideInviteAvatars = false
        }
        
        let previousState = state.hideInviteAvatars
        state.isWaitingHideInviteAvatars = true
        state.hideInviteAvatars = value
        // If the other value is updating wait also for it to finish
        await timelineMediaVisibilityTask?.value
        
        switch await clientProxy.setHideInviteAvatars(value) {
        case .success:
            break
        case .failure:
            state.hideInviteAvatars = previousState
            userIndicatorController.submitIndicator(.init(title: L10n.errorUnknown))
        }
    }
}
