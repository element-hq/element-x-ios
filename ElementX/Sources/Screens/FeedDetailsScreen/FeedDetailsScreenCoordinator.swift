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
    let feedProtocol: FeedProtocol?
    let feedItem: HomeScreenPost
    let isFeedDetailsRefreshable: Bool
}

enum FeedDetailsScreenCoordinatorAction {
    case replyTapped(_ reply: HomeScreenPost)
    case attachMedia(FeedMediaSelectedProtocol)
    case openPostUserProfile(_ profile: ZPostUserProfile)
}

final class FeedDetailsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: FeedDetailsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<FeedDetailsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    private let isFeedDetailsRefreshable: Bool
    
    var actions: AnyPublisher<FeedDetailsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: FeedDetailsScreenCoordinatorParameters) {
        self.isFeedDetailsRefreshable = parameters.isFeedDetailsRefreshable
        viewModel = FeedDetailsScreenViewModel(userSession: parameters.userSession,
                                               feedProtocol: parameters.feedProtocol,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               feedItem: parameters.feedItem)
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .replyTapped(let reply):
                    actionsSubject.send(.replyTapped(reply))
                case .attachMedia(let attachMediaProtocol):
                    actionsSubject.send(.attachMedia(attachMediaProtocol))
                case .openPostUserProfile(let profile):
                    actionsSubject.send(.openPostUserProfile(profile))
                }
            }
            .store(in: &cancellables)
    }
            
    func toPresentable() -> AnyView {
        AnyView(FeedDetailsScreen(context: viewModel.context, isRefreshable: isFeedDetailsRefreshable))
    }
}
