//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SpaceSettingsScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let userSession: UserSessionProtocol
    let analyticsService: AnalyticsService
    let userIndicator: UserIndicatorControllerProtocol
    let notificationSettingsProxy: NotificationSettingsProxyProtocol
    let attributedStringBuilder: AttributedStringBuilderProtocol
    let appSettings: AppSettings
}

enum SpaceSettingsScreenCoordinatorAction { }

final class SpaceSettingsScreenCoordinator: CoordinatorProtocol {
    private let viewModel: RoomDetailsScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<SpaceSettingsScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceSettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SpaceSettingsScreenCoordinatorParameters) {
        viewModel = RoomDetailsScreenViewModel(roomProxy: parameters.roomProxy,
                                               userSession: parameters.userSession,
                                               analyticsService: parameters.analyticsService,
                                               userIndicatorController: parameters.userIndicator,
                                               notificationSettingsProxy: parameters.notificationSettingsProxy,
                                               attributedStringBuilder: parameters.attributedStringBuilder,
                                               appSettings: parameters.appSettings)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            guard let self else { return }
            
            switch action {
            case .requestNotificationSettingsPresentation, .requestRecipientDetailsPresentation, .requestInvitePeoplePresentation, .leftRoom, .requestPollsHistoryPresentation, .requestRolesAndPermissionsPresentation, .startCall, .displayPinnedEventsTimeline, .displayMediaEventsTimeline, .displayKnockingRequests, .displayReportRoom:
                break // Not handled in this context
            case .requestEditDetailsPresentation:
                break // TODO:
            case .displaySecurityAndPrivacy:
                break // TODO:
            case .transferOwnership:
                break // TODO:
            case .requestMemberDetailsPresentation:
                break // TODO:
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SpaceSettingsScreen(context: viewModel.context))
    }
}
