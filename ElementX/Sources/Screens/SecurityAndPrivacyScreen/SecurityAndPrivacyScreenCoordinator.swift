//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

// periphery:ignore:all - this is just a securityAndPrivacy remove this comment once generating the final file

import Combine
import SwiftUI

struct SecurityAndPrivacyScreenCoordinatorParameters { }

enum SecurityAndPrivacyScreenCoordinatorAction {
    case done
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}

final class SecurityAndPrivacyScreenCoordinator: CoordinatorProtocol {
    private let parameters: SecurityAndPrivacyScreenCoordinatorParameters
    private let viewModel: SecurityAndPrivacyScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<SecurityAndPrivacyScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SecurityAndPrivacyScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SecurityAndPrivacyScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SecurityAndPrivacyScreenViewModel()
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .done:
                actionsSubject.send(.done)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SecurityAndPrivacyScreen(context: viewModel.context))
    }
}
