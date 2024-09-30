//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomDetailsScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let clientProxy: ClientProxyProtocol
    let mediaProvider: MediaProviderProtocol
    let analyticsService: AnalyticsService
    let userIndicatorController: UserIndicatorControllerProtocol
    let notificationSettings: NotificationSettingsProxyProtocol
    let attributedStringBuilder: AttributedStringBuilderProtocol
    let appMediator: AppMediatorProtocol
}

enum RoomDetailsScreenCoordinatorAction {
    case leftRoom
    case presentRoomMembersList
    case presentRoomDetailsEditScreen
    case presentNotificationSettingsScreen
    case presentInviteUsersScreen
    case presentPollsHistory
    case presentRolesAndPermissionsScreen
    case presentCall
    case presentPinnedEventsTimeline
}

final class RoomDetailsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomDetailsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<RoomDetailsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
        
    var actions: AnyPublisher<RoomDetailsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
        
    init(parameters: RoomDetailsScreenCoordinatorParameters) {
        viewModel = RoomDetailsScreenViewModel(roomProxy: parameters.roomProxy,
                                               clientProxy: parameters.clientProxy,
                                               mediaProvider: parameters.mediaProvider,
                                               analyticsService: parameters.analyticsService,
                                               userIndicatorController: parameters.userIndicatorController,
                                               notificationSettingsProxy: parameters.notificationSettings,
                                               attributedStringBuilder: parameters.attributedStringBuilder,
                                               appMediator: parameters.appMediator,
                                               appSettings: ServiceLocator.shared.settings)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .requestMemberDetailsPresentation:
                    actionsSubject.send(.presentRoomMembersList)
                case .requestInvitePeoplePresentation:
                    actionsSubject.send(.presentInviteUsersScreen)
                case .leftRoom:
                    actionsSubject.send(.leftRoom)
                case .requestEditDetailsPresentation:
                    actionsSubject.send(.presentRoomDetailsEditScreen)
                case .requestNotificationSettingsPresentation:
                    actionsSubject.send(.presentNotificationSettingsScreen)
                case .requestPollsHistoryPresentation:
                    actionsSubject.send(.presentPollsHistory)
                case .requestRolesAndPermissionsPresentation:
                    actionsSubject.send(.presentRolesAndPermissionsScreen)
                case .startCall:
                    actionsSubject.send(.presentCall)
                case .displayPinnedEventsTimeline:
                    actionsSubject.send(.presentPinnedEventsTimeline)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        AnyView(RoomDetailsScreen(context: viewModel.context))
    }
}
