//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

protocol FlowCoordinatorProtocol {
    func start(animated: Bool)
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool)
    func clearRoute(animated: Bool)
}

extension FlowCoordinatorProtocol {
    func start() {
        start(animated: true)
    }
}

/// Core parameters that are shared across the main flows for easy dependency injection.
///
/// Please do **not** pass this type directly to screen coordinators/view models.
struct CommonFlowParameters {
    /// The session of the account this flow tree belongs to. It never changes, even when another account becomes active.
    let userSession: UserSessionProtocol
    /// Every signed in account, most recently active first, so the first one is `userSession`'s.
    let availableSessionsPublisher: CurrentValuePublisher<[UserSessionDetails], Never>
    let bugReportService: BugReportServiceProtocol
    let elementCallService: ElementCallServiceProtocol
    let timelineControllerFactory: TimelineControllerFactoryProtocol
    let emojiProvider: EmojiProviderProtocol
    let linkMetadataProvider: LinkMetadataProviderProtocol
    let appMediator: AppMediatorProtocol
    let appHooks: AppHooks
    let analytics: AnalyticsServiceProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    let notificationManager: NotificationManagerProtocol
    let stateMachineFactory: StateMachineFactoryProtocol
    
    var windowManager: WindowManagerProtocol {
        appMediator.windowManager
    }
    
    var ongoingCallRoomIDPublisher: CurrentValuePublisher<String?, Never> {
        elementCallService.ongoingCallRoomIDPublisher
    }
}
