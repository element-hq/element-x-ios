//
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
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
