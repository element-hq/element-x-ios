//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    case deactivateAccount
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
                case .deactivateAccount:
                    actionsSubject.send(.deactivateAccount)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(SettingsScreen(context: viewModel.context))
    }
}
