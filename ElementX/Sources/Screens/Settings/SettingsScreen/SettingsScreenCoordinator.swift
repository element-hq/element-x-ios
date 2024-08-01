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

struct SettingsScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let appSettings: AppSettings
}

enum SettingsScreenCoordinatorAction {
    case dismiss
    case logout
    case secureBackup
    case userDetails
    case analytics
    case appLock
    case bugReport
    case about
    case blockedUsers
    case manageAccount(url: URL)
    case notifications
    case advancedSettings
    case developerOptions
}

final class SettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: SettingsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<SettingsScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Setup
    
    init(parameters: SettingsScreenCoordinatorParameters) {
        viewModel = SettingsScreenViewModel(userSession: parameters.userSession)
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .close:
                    actionsSubject.send(.dismiss)
                case .userDetails:
                    actionsSubject.send(.userDetails)
                case let .manageAccount(url):
                    actionsSubject.send(.manageAccount(url: url))
                case .analytics:
                    actionsSubject.send(.analytics)
                case .appLock:
                    actionsSubject.send(.appLock)
                case .reportBug:
                    actionsSubject.send(.bugReport)
                case .about:
                    actionsSubject.send(.about)
                case .blockedUsers:
                    actionsSubject.send(.blockedUsers)
                case .secureBackup:
                    actionsSubject.send(.secureBackup)
                case .notifications:
                    actionsSubject.send(.notifications)
                case .advancedSettings:
                    actionsSubject.send(.advancedSettings)
                case .developerOptions:
                    actionsSubject.send(.developerOptions)
                case .logout:
                    actionsSubject.send(.logout)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(SettingsScreen(context: viewModel.context))
    }
}
