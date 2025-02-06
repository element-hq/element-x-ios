//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct FeedDetailsScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let feedItem: HomeScreenPost
}

enum FeedDetailsScreenCoordinatorAction {
    case replyTapped(_ reply: HomeScreenPost)
}

final class FeedDetailsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: FeedDetailsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<FeedDetailsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<FeedDetailsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: FeedDetailsScreenCoordinatorParameters) {
        viewModel = FeedDetailsScreenViewModel(userSession: parameters.userSession, feedItem: parameters.feedItem)
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .replyTapped(let reply):
                    actionsSubject.send(.replyTapped(reply))
                }
            }
            .store(in: &cancellables)
    }
            
    func toPresentable() -> AnyView {
        AnyView(FeedDetailsScreen(context: viewModel.context))
    }
}
