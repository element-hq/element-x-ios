//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

// periphery:ignore:all - this is just a template remove this comment once generating the final file

import Combine
import SwiftUI

struct TemplateScreenCoordinatorParameters { }

enum TemplateScreenCoordinatorAction {
    case done
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}

final class TemplateScreenCoordinator: CoordinatorProtocol {
    private let parameters: TemplateScreenCoordinatorParameters
    private let viewModel: TemplateScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<TemplateScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<TemplateScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: TemplateScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = TemplateScreenViewModel()
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
        AnyView(TemplateScreen(context: viewModel.context))
    }
}
