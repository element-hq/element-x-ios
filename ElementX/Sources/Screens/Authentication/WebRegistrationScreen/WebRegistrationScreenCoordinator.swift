//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

struct WebRegistrationScreenCoordinatorParameters {
    /// The service used to authenticate the user.
    let authenticationService: AuthenticationServiceProtocol
    
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum WebRegistrationScreenCoordinatorAction: CustomStringConvertible {
    case cancel
    case signedIn(UserSessionProtocol)
    
    var description: String {
        switch self {
        case .cancel: "cancel"
        case .signedIn: "signedIn"
        }
    }
}

// Note: This code was based on the LoginScreen, we should move the authentication service logic into the view model.
final class WebRegistrationScreenCoordinator: CoordinatorProtocol {
    private let parameters: WebRegistrationScreenCoordinatorParameters
    private let viewModel: WebRegistrationScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<WebRegistrationScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<WebRegistrationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: WebRegistrationScreenCoordinatorParameters) {
        self.parameters = parameters
        
        guard let registrationHelperURL = parameters.authenticationService.homeserver.value.registrationHelperURL else {
            MXLog.error("Attempted registration without a helper URL.")
            fatalError("A helper URL is required.")
        }
        viewModel = WebRegistrationScreenViewModel(registrationHelperURL: registrationHelperURL)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .cancel:
                actionsSubject.send(.cancel)
            case .signedIn(let credentials):
                Task { await self.completeRegistration(using: credentials) }
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(WebRegistrationScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func completeRegistration(using credentials: WebRegistrationCredentials) async {
        switch await parameters.authenticationService.completeWebRegistration(using: credentials) {
        case .success(let userSession):
            actionsSubject.send(.signedIn(userSession))
        case .failure(let error):
            MXLog.error("Failed registration: \(error)")
            parameters.userIndicatorController.alertInfo = .init(id: UUID(), title: L10n.errorUnknown, message: String(describing: error))
        }
    }
}
