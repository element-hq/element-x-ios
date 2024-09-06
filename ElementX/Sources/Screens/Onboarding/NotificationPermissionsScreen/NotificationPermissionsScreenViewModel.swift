//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias NotificationPermissionsScreenViewModelType = StateStoreViewModel<NotificationPermissionsScreenViewState, NotificationPermissionsScreenViewAction>

class NotificationPermissionsScreenViewModel: NotificationPermissionsScreenViewModelType, NotificationPermissionsScreenViewModelProtocol {
    private let notificationManager: NotificationManagerProtocol
    
    private var actionsSubject: PassthroughSubject<NotificationPermissionsScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<NotificationPermissionsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(notificationManager: NotificationManagerProtocol) {
        self.notificationManager = notificationManager
        
        super.init(initialViewState: .init())
    }

    // MARK: - Public
    
    override func process(viewAction: NotificationPermissionsScreenViewAction) {
        switch viewAction {
        case .enable:
            notificationManager.requestAuthorization()
            
            actionsSubject.send(.done)
        case .notNow:
            actionsSubject.send(.done)
        }
    }
}
