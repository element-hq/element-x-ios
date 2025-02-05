//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct FeedDetailsScreenViewState: BindableState {
    var bindings: FeedDetailsScreenViewStateBindings
}

struct FeedDetailsScreenViewStateBindings {
    var feed: HomeScreenPost = HomeScreenPost.placeholder()
    var feedReplies: [ZPost] = []
}

enum FeedDetailsScreenViewAction { }
