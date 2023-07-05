//
// Copyright 2022 New Vector Ltd
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

typealias NotificationsSettingsScreenViewModelType = StateStoreViewModel<NotificationsSettingsScreenViewState, NotificationsSettingsScreenViewAction>

class NotificationsSettingsScreenViewModel: NotificationsSettingsScreenViewModelType, NotificationsSettingsScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<NotificationsSettingsScreenViewModelAction, Never> = .init()
    private let appSettings: AppSettings
    
    var actions: AnyPublisher<NotificationsSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(appSettings: AppSettings) {
        self.appSettings = appSettings
        let bindings = NotificationsSettingsScreenViewStateBindings(enableNotifications: appSettings.enableNotifications)
        super.init(initialViewState: NotificationsSettingsScreenViewState(bindings: bindings))
        
        appSettings.$enableNotifications
            .weakAssign(to: \.state.bindings.enableNotifications, on: self)
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    override func process(viewAction: NotificationsSettingsScreenViewAction) {
        switch viewAction {
        case .changedEnableNotifications:
            toogleNotifications()
        }
    }
    
    // MARK: - Private
    
    func toogleNotifications() {
        appSettings.enableNotifications.toggle()
    }
}
