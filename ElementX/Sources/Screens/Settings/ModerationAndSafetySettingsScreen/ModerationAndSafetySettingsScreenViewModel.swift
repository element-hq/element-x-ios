//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ModerationAndSafetySettingsScreenViewModelType = StateStoreViewModelV2<ModerationAndSafetySettingsScreenViewState, ModerationAndSafetySettingsScreenViewAction>

class ModerationAndSafetySettingsScreenViewModel: ModerationAndSafetySettingsScreenViewModelType, ModerationAndSafetySettingsScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var timelineMediaVisibilityTask: Task<Void, Never>?
    private var hideInviteAvatarsTask: Task<Void, Never>?
    
    private var actionsSubject: PassthroughSubject<ModerationAndSafetySettingsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ModerationAndSafetySettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        clientProxy = userSession.clientProxy
        self.userIndicatorController = userIndicatorController
        
        let state = ModerationAndSafetySettingsScreenViewState(hideInviteAvatars: clientProxy.hideInviteAvatarsPublisher.value,
                                                               timelineMediaVisibility: clientProxy.timelineMediaVisibilityPublisher.value,
                                                               bindings: .init(userSettings: userSession.userSettings))
        super.init(initialViewState: state)
        
        clientProxy.hideInviteAvatarsPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.hideInviteAvatars, on: self)
            .store(in: &cancellables)
        
        clientProxy.timelineMediaVisibilityPublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.timelineMediaVisibility, on: self)
            .store(in: &cancellables)
        
        clientProxy.ignoredUsersPublisher
            .receive(on: DispatchQueue.main)
            .map { $0?.isEmpty == false }
            .weakAssign(to: \.state.showBlockedUsers, on: self)
            .store(in: &cancellables)
    }
    
    override func process(viewAction: ModerationAndSafetySettingsScreenViewAction) {
        switch viewAction {
        case let .updateHideInviteAvatars(value):
            hideInviteAvatarsTask = Task { [weak self] in await self?.updateHideInviteAvatars(value) }
        case let .updateTimelineMediaVisibility(value):
            timelineMediaVisibilityTask = Task { [weak self] in await self?.updateTimelineMediaVisibility(value) }
        case .blockedUsers:
            actionsSubject.send(.blockedUsers)
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
