//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SettingsScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let isBugReportServiceEnabled: Bool
    let isInSecondaryWindow: Bool
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum SettingsScreenCoordinatorAction {
    case dismiss
    
    case userDetails
    case userStatusEmojiPicker(EmojiPickerScreenContinuation)
    
    case addAccount
    
    case manageAccount(url: URL)
    case linkNewDevice
    case notifications
    case secureBackup
    case moderationAndSafety
    case bugReport
    
    case logout
    case deactivateAccount
    
    case mediaUploadQuality
    case appLock
    case locationSharing
    case analytics
    case labs
    case about
    
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
        viewModel = SettingsScreenViewModel(userSession: parameters.userSession,
                                            isBugReportServiceEnabled: parameters.isBugReportServiceEnabled,
                                            isInSecondaryWindow: parameters.isInSecondaryWindow,
                                            userIndicatorController: parameters.userIndicatorController)
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .close:
                    actionsSubject.send(.dismiss)
                    
                case .userDetails:
                    actionsSubject.send(.userDetails)
                case let .userStatusEmojiPicker(continuation):
                    actionsSubject.send(.userStatusEmojiPicker(continuation))
                    
                case .addAccount:
                    actionsSubject.send(.addAccount)
                    
                case let .manageAccount(url):
                    actionsSubject.send(.manageAccount(url: url))
                case .linkNewDevice:
                    actionsSubject.send(.linkNewDevice)
                case .notifications:
                    actionsSubject.send(.notifications)
                case .secureBackup:
                    actionsSubject.send(.secureBackup)
                case .moderationAndSafety:
                    actionsSubject.send(.moderationAndSafety)
                case .reportBug:
                    actionsSubject.send(.bugReport)
                    
                case .logout:
                    actionsSubject.send(.logout)
                case .deactivateAccount:
                    actionsSubject.send(.deactivateAccount)
                    
                case .mediaUploadQuality:
                    actionsSubject.send(.mediaUploadQuality)
                case .appLock:
                    actionsSubject.send(.appLock)
                case .locationSharing:
                    actionsSubject.send(.locationSharing)
                case .analytics:
                    actionsSubject.send(.analytics)
                case .labs:
                    actionsSubject.send(.labs)
                case .about:
                    actionsSubject.send(.about)
                    
                case .developerOptions:
                    actionsSubject.send(.developerOptions)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(SettingsScreen(context: viewModel.context))
    }
}
