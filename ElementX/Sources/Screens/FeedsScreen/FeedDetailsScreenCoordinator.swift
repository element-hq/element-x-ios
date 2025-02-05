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

final class FeedDetailsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: FeedDetailsScreenViewModelProtocol
    
    init(parameters: FeedDetailsScreenCoordinatorParameters) {
        viewModel = FeedDetailsScreenViewModel(userSession: parameters.userSession, feedItem: parameters.feedItem)
    }
            
    func toPresentable() -> AnyView {
        AnyView(FeedDetailsScreen(context: viewModel.context))
    }
}
