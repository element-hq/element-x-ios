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

import SwiftUI

struct ServerSelectionCoordinatorParameters {
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProxyProtocol
    let userNotificationController: UserNotificationControllerProtocol
    /// Whether the screen is presented modally or within a navigation stack.
    let isModallyPresented: Bool
}

enum ServerSelectionCoordinatorAction {
    case updated
    case dismiss
}

final class ServerSelectionCoordinator: CoordinatorProtocol {
    private let parameters: ServerSelectionCoordinatorParameters
    private let userNotificationController: UserNotificationControllerProtocol
    private var viewModel: ServerSelectionViewModelProtocol
    private var authenticationService: AuthenticationServiceProxyProtocol { parameters.authenticationService }

    var callback: (@MainActor (ServerSelectionCoordinatorAction) -> Void)?
    
    init(parameters: ServerSelectionCoordinatorParameters) {
        self.parameters = parameters
        viewModel = ServerSelectionViewModel(homeserverAddress: parameters.authenticationService.homeserver.address,
                                             isModallyPresented: parameters.isModallyPresented)
        userNotificationController = parameters.userNotificationController
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }
            MXLog.debug("ServerSelectionViewModel did callback with action: \(action).")
            
            switch action {
            case .confirm(let homeserverAddress):
                self.useHomeserver(homeserverAddress)
            case .dismiss:
                self.callback?(.dismiss)
            }
        }
    }
    
    func stop() {
        stopLoading()
    }
    
    func toPresentable() -> AnyView {
        AnyView(ServerSelectionScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = ElementL10n.loading, isInteractionBlocking: Bool = true) {
        userNotificationController.submitNotification(UserNotification(type: .modal,
                                                                       title: label,
                                                                       persistent: true))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        userNotificationController.retractAllNotifications()
    }
    
    /// Updates the login flow using the supplied homeserver address, or shows an error when this isn't possible.
    private func useHomeserver(_ homeserverAddress: String) {
        startLoading()
        
        Task {
            switch await authenticationService.configure(for: homeserverAddress) {
            case .success:
                callback?(.updated)
                stopLoading()
            case .failure(let error):
                stopLoading()
                handleError(error)
            }
        }
    }
    
    /// Processes an error to either update the flow or display it to the user.
    private func handleError(_ error: AuthenticationServiceError) {
        switch error {
        case .invalidServer, .invalidHomeserverAddress:
            viewModel.displayError(.footerMessage(ElementL10n.loginErrorHomeserverNotFound))
        default:
            viewModel.displayError(.footerMessage(ElementL10n.unknownError))
        }
    }
}
