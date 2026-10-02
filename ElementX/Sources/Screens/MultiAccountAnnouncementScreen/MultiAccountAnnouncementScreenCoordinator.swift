//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

enum MultiAccountAnnouncementScreenCoordinatorAction {
    case addAccount
    case dismiss
}

final class MultiAccountAnnouncementScreenCoordinator: CoordinatorProtocol {
    private let viewModel: MultiAccountAnnouncementScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<MultiAccountAnnouncementScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<MultiAccountAnnouncementScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init() {
        viewModel = MultiAccountAnnouncementScreenViewModel()
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .addAccount:
                actionsSubject.send(.addAccount)
            case .dismiss:
                actionsSubject.send(.dismiss)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(MultiAccountAnnouncementScreen(context: viewModel.context))
    }
}
