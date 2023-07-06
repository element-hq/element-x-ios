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

typealias NotificationSettingsScreenViewModelType = StateStoreViewModel<NotificationSettingsScreenViewState, NotificationSettingsScreenViewAction>

class NotificationSettingsScreenViewModel: NotificationSettingsScreenViewModelType, NotificationSettingsScreenViewModelProtocol {
    private var actionsSubject: PassthroughSubject<NotificationSettingsScreenViewModelAction, Never> = .init()
    private let appSettings: AppSettings
    private let userNotificationCenter: UserNotificationCenterProtocol
    
    var actions: AnyPublisher<NotificationSettingsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(appSettings: AppSettings, userNotificationCenter: UserNotificationCenterProtocol) {
        self.appSettings = appSettings
        self.userNotificationCenter = userNotificationCenter
        let bindings = NotificationSettingsScreenViewStateBindings(enableNotifications: appSettings.enableNotifications)
        super.init(initialViewState: NotificationSettingsScreenViewState(bindings: bindings))
                
        // Listen for changes to AppSettings.enableNotifications
        appSettings.$enableNotifications
            .weakAssign(to: \.state.bindings.enableNotifications, on: self)
            .store(in: &cancellables)
        
        // Refresh authorization status uppon UIApplication.didBecomeActiveNotification notification
        NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)
            .sink { [weak self] _ in
                Task {
                    await self?.readSystemAuthorizationStatus()
                }
            }
            .store(in: &cancellables)
        
        Task {
            await readSystemAuthorizationStatus()
        }
    }
        
    // MARK: - Public
    
    override func process(viewAction: NotificationSettingsScreenViewAction) {
        switch viewAction {
        case .openSystemSettings:
            Task {
                await openSystemSettings()
            }
        case .changedEnableNotifications:
            toogleNotifications()
        }
    }
    
    // MARK: - Private
    
    @MainActor
    func readSystemAuthorizationStatus() async {
        state.isUserPermissionGranted = await userNotificationCenter.getAuthorizationStatus() == .authorized
    }

    func openSystemSettings() async {
        // Note: UIApplication.openNotificationSettingsURLString doesn't work on a simulator
        if let url = URL(string: UIApplication.openSettingsURLString) {
            await UIApplication.shared.open(url)
        }
    }
    
    func toogleNotifications() {
        appSettings.enableNotifications.toggle()
    }
}
