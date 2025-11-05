//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomDetailsScreenCoordinatorParameters {
    let roomProxy: JoinedRoomProxyProtocol
    let userSession: UserSessionProtocol
    let analyticsService: AnalyticsService
    let userIndicatorController: UserIndicatorControllerProtocol
    let notificationSettings: NotificationSettingsProxyProtocol
    let attributedStringBuilder: AttributedStringBuilderProtocol
    let appSettings: AppSettings
}

enum RoomDetailsScreenCoordinatorAction {
    case leftRoom
    case presentRoomMembersList
    case presentRecipientDetails(userID: String)
    case presentRoomDetailsEditScreen
    case presentNotificationSettingsScreen
    case presentInviteUsersScreen
    case presentPollsHistory
    case presentRolesAndPermissionsScreen
    case presentCall
    case presentPinnedEventsTimeline
    case presentMediaEventsTimeline
    case presentKnockingRequestsListScreen
    case presentSecurityAndPrivacyScreen
    case presentReportRoomScreen
    case transferOwnership
}

final class RoomDetailsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: RoomDetailsScreenViewModelProtocol
    private let isSpace: Bool
    
    private let actionsSubject: PassthroughSubject<RoomDetailsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
        
    var actions: AnyPublisher<RoomDetailsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
        
    init(parameters: RoomDetailsScreenCoordinatorParameters) {
        isSpace = parameters.roomProxy.infoPublisher.value.isSpace
        viewModel = RoomDetailsScreenViewModel(roomProxy: parameters.roomProxy,
                                               userSession: parameters.userSession,
                                               analyticsService: parameters.analyticsService,
                                               userIndicatorController: parameters.userIndicatorController,
                                               notificationSettingsProxy: parameters.notificationSettings,
                                               attributedStringBuilder: parameters.attributedStringBuilder,
                                               appSettings: parameters.appSettings)
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
                case .displayMediaEventsTimeline:
                    actionsSubject.send(.presentMediaEventsTimeline)
                case .displayKnockingRequests:
                    actionsSubject.send(.presentKnockingRequestsListScreen)
                case .displaySecurityAndPrivacy:
                    actionsSubject.send(.presentSecurityAndPrivacyScreen)
                case .requestRecipientDetailsPresentation(let userID):
                    actionsSubject.send(.presentRecipientDetails(userID: userID))
                case .displayReportRoom:
                    actionsSubject.send(.presentReportRoomScreen)
                case .transferOwnership:
                    actionsSubject.send(.transferOwnership)
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        viewModel.stop()
    }
    
    func toPresentable() -> AnyView {
        if isSpace {
            AnyView(SpaceSettingsScreen(context: viewModel.context))
        } else {
            AnyView(RoomDetailsScreen(context: viewModel.context))
        }
    }
}
