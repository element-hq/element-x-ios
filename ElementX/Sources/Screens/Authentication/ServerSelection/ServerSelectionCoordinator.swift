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

import SwiftUI

struct ServerSelectionCoordinatorParameters {
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProtocol
    /// Whether the screen is presented modally or within a navigation stack.
    let hasModalPresentation: Bool
}

enum ServerSelectionCoordinatorAction {
    case updated
    case dismiss
}

final class ServerSelectionCoordinator: Coordinator, Presentable {
    
    // MARK: - Properties
    
    // MARK: Private
    
    private let parameters: ServerSelectionCoordinatorParameters
    private let serverSelectionHostingController: UIViewController
    private var serverSelectionViewModel: ServerSelectionViewModelProtocol
    
    private var authenticationService: AuthenticationServiceProtocol { parameters.authenticationService }
    private var indicatorPresenter: UserIndicatorTypePresenterProtocol
    private var loadingIndicator: UserIndicator?
    
    // MARK: Public

    // Must be used only internally
    var childCoordinators: [Coordinator] = []
    var callback: (@MainActor (ServerSelectionCoordinatorAction) -> Void)?
    
    // MARK: - Setup
    
    init(parameters: ServerSelectionCoordinatorParameters) {
        self.parameters = parameters
        
        let viewModel = ServerSelectionViewModel(homeserverAddress: parameters.authenticationService.homeserver.address,
                                                 hasModalPresentation: parameters.hasModalPresentation)
        let view = ServerSelectionScreen(context: viewModel.context)
        serverSelectionViewModel = viewModel
        serverSelectionHostingController = UIHostingController(rootView: view)
        
        indicatorPresenter = UserIndicatorTypePresenter(presentingViewController: serverSelectionHostingController)
    }
    
    // MARK: - Public
    
    func start() {
        MXLog.debug("[ServerSelectionCoordinator] did start.")
        
        serverSelectionViewModel.callback = { [weak self] action in
            guard let self = self else { return }
            MXLog.debug("[ServerSelectionCoordinator] ServerSelectionViewModel did callback with action: \(action).")
            
            switch action {
            case .confirm(let homeserverAddress):
                self.useHomeserver(homeserverAddress)
            case .dismiss:
                self.callback?(.dismiss)
            }
        }
    }
    
    func toPresentable() -> UIViewController {
        serverSelectionHostingController
    }
    
    // MARK: - Private
    
    /// Show an activity indicator whilst loading.
    /// - Parameters:
    ///   - label: The label to show on the indicator.
    ///   - isInteractionBlocking: Whether the indicator should block any user interaction.
    private func startLoading(label: String = ElementL10n.loading, isInteractionBlocking: Bool = true) {
        loadingIndicator = indicatorPresenter.present(.loading(label: label, isInteractionBlocking: isInteractionBlocking))
    }
    
    /// Hide the currently displayed activity indicator.
    private func stopLoading() {
        loadingIndicator = nil
    }
    
    /// Updates the login flow using the supplied homeserver address, or shows an error when this isn't possible.
    private func useHomeserver(_ homeserverAddress: String) {
        startLoading()
        
        Task {
            switch await authenticationService.startLogin(for: homeserverAddress) {
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
    private func handleError(_ error: Error) {
        switch error {
        case AuthenticationServiceError.invalidServer:
            serverSelectionViewModel.displayError(.footerMessage(ElementL10n.loginErrorHomeserverNotFound))
        default:
            serverSelectionViewModel.displayError(.footerMessage(ElementL10n.unknownError))
        }
    }
}
