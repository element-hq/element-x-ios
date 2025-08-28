//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a bookmarks remove this comment once generating the final file

import Combine
import SwiftUI

struct BookmarksScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
}

enum BookmarksScreenCoordinatorAction {
    case dismiss
}

final class BookmarksScreenCoordinator: CoordinatorProtocol {
    private let parameters: BookmarksScreenCoordinatorParameters
    private let viewModel: BookmarksScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<BookmarksScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<BookmarksScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: BookmarksScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = BookmarksScreenViewModel(clientProxy: parameters.clientProxy)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(BookmarksScreen(context: viewModel.context))
    }
}
