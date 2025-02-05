//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias FeedDetailsScreenViewModelType = StateStoreViewModel<FeedDetailsScreenViewState, FeedDetailsScreenViewAction>

class FeedDetailsScreenViewModel:
    FeedDetailsScreenViewModelType,
    FeedDetailsScreenViewModelProtocol {
    init(userSession: UserSessionProtocol,
         feedItem: HomeScreenPost) {
        super.init(
            initialViewState: .init(
                bindings: .init(feed: feedItem)
            )
        )
        
//        userSession.clientProxy.userRewardsPublisher
//            .receive(on: DispatchQueue.main)
//            .weakAssign(to: \.state.bindings.userRewards, on: self)
//            .store(in: &cancellables)
//        
//        Task {
//            await userSession.clientProxy.getUserRewards(shouldCheckRewardsIntiamtion: false)
//        }
    }
}
