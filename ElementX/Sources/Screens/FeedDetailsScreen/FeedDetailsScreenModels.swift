//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct FeedDetailsScreenViewState: BindableState {
    let userID: String
    var userAvatarURL: URL?
    
    var bindings: FeedDetailsScreenViewStateBindings
    
    var feedReplies: [HomeScreenPost] = []
    var repliesListMode: FeedRepliesListMode = .skeletons
    
    var canLoadMoreReplies: Bool = true
    
    var visibleReplies: [HomeScreenPost] {
        if repliesListMode == .skeletons {
            return placeholderReplies
        }
        
        return feedReplies
    }
    
    var placeholderReplies: [HomeScreenPost] {
        (1...10).map { _ in
            HomeScreenPost.placeholder()
        }
    }
    
    var userRewards = ZeroRewards.empty()
    
    var postRepliesMediaInfoMap: [String: HomeScreenPostMediaInfo] = [:]
}

struct FeedDetailsScreenViewStateBindings {
    var myPostReply: String = ""
    
    var feed: HomeScreenPost = HomeScreenPost.placeholder()
    var alertInfo: AlertInfo<UUID>?
}

enum FeedDetailsScreenViewModelAction {
    case replyTapped(_ reply: HomeScreenPost)
}

enum FeedDetailsScreenViewAction {
    case replyTapped(_ reply: HomeScreenPost)
    case openArweaveLink(_ post: HomeScreenPost)
    case loadMoreRepliesIfNeeded
    case forceRefreshFeed
    case meowTapped(_ postId: String, amount: Int, isPostAReply: Bool)
    case postReply
}

enum FeedRepliesListMode: CustomStringConvertible {
    case skeletons
    case empty
    case replies
    
    var description: String {
        switch self {
        case .skeletons:
            return "Showing placeholders"
        case .empty:
            return "Showing empty state"
        case .replies:
            return "Showing replies"
        }
    }
}
