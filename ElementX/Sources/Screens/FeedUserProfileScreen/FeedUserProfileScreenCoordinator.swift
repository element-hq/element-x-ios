//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct FeedUserProfileScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let feedUpdatedProtocol: FeedDetailsUpdatedProtocol?
    let userProfile: ZPostUserProfile
}

enum FeedUserProfileScreenCoordinatorAction {
    case feedTapped(_ feed: HomeScreenPost)
    case openDirectChat(_ roomId: String)
    case newFeed(CreateFeedProtocol)
}

final class FeedUserProfileScreenCoordinator: CoordinatorProtocol {
    private var viewModel: FeedUserProfileScreenViewModel
    
    private let actionsSubject: PassthroughSubject<FeedUserProfileScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<FeedUserProfileScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: FeedUserProfileScreenCoordinatorParameters) {
        viewModel = FeedUserProfileScreenViewModel(clientProxy: parameters.userSession.clientProxy,
                                                   mediaProvider: parameters.userSession.mediaProvider,
                                                   feedUpdatedProtocol: parameters.feedUpdatedProtocol,
                                                   userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                                   userProfile: parameters.userProfile)
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .feedTapped(let feed):
                    actionsSubject.send(.feedTapped(feed))
                case .openDirectChat(let roomId):
                    actionsSubject.send(.openDirectChat(roomId))
                case .newFeed(let createFeedProtocol):
                    actionsSubject.send(.newFeed(createFeedProtocol))
                }
            }
            .store(in: &cancellables)
    }
            
    func toPresentable() -> AnyView {
        AnyView(FeedUserProfileScreenView(context: viewModel.context))
    }
}
