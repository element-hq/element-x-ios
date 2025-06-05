//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct FeedUserProfileScreenViewState: BindableState {
    let userID: String
    var userProfile: ZPostUserProfile
    var userFollowStatus: ZPostUserFollowingStatus? = nil
    var shouldShowFollowButton: Bool = true
    var shouldShowDirectChatButton: Bool = true
    
    var bindings: FeedUserProfileScreenViewStateBindings
    
    var userFeeds: [HomeScreenPost] = []
    var userFeedsListMode: UserFeedsListMode = .skeletons
    
    var canLoadMoreFeeds: Bool = true
    
    var visibleFeeds: [HomeScreenPost] {
        if userFeedsListMode == .skeletons {
            return placeholderFeeds
        }
        
        return userFeeds
    }
    
    var placeholderFeeds: [HomeScreenPost] {
        (1...10).map { _ in
            HomeScreenPost.placeholder()
        }
    }
    
    var userRewards = ZeroRewards.empty()
    
    var userFeedsMediaInfoMap: [String: HomeScreenPostMediaInfo] = [:]
    var userFeedsLinkPreviewsMap: [String: ZLinkPreview] = [:]
}

struct FeedUserProfileScreenViewStateBindings {
    var alertInfo: AlertInfo<UUID>?
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: MediaPreviewItem?
}

enum FeedUserProfileScreenViewModelAction {
    case feedTapped(_ feed: HomeScreenPost)
    case openDirectChat(_ roomId: String)
}

enum FeedUserProfileScreenViewAction {
    case feedTapped(_ feed: HomeScreenPost)
    case openArweaveLink(_ post: HomeScreenPost)
    case openYoutubeLink(_ url: String)
    case loadMoreFeedsIfNeeded
    case addMeowToPost(postId: String, amount: Int)
    case toggleFollowUser
    case openDirectChat
    case displayAvatar(_ url: URL)
}

enum UserFeedsListMode: CustomStringConvertible {
    case skeletons
    case empty
    case feeds
    
    var description: String {
        switch self {
        case .skeletons:
            return "Showing placeholders"
        case .empty:
            return "Showing empty state"
        case .feeds:
            return "Showing feeds"
        }
    }
}
