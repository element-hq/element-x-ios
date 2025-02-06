//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias FeedDetailsScreenViewModelType = StateStoreViewModel<FeedDetailsScreenViewState, FeedDetailsScreenViewAction>

class FeedDetailsScreenViewModel: FeedDetailsScreenViewModelType, FeedDetailsScreenViewModelProtocol {
    
    private let clientProxy: ClientProxyProtocol
    
    private let POST_REPLIES_PAGE_COUNT = 10
    private var isFetchRepliesInProgress = false
    
    private var actionsSubject: PassthroughSubject<FeedDetailsScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<FeedDetailsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol, feedItem: HomeScreenPost) {
        self.clientProxy = userSession.clientProxy
        
        super.init(initialViewState: .init(bindings: .init(feed: feedItem)), mediaProvider: userSession.mediaProvider)
        
        userSession.clientProxy.userRewardsPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userRewards, on: self)
            .store(in: &cancellables)
        
        fetchFeed(feedItem.id)
        fetchFeedReplies(feedItem.id)
    }
    
    override func process(viewAction: FeedDetailsScreenViewAction) {
        switch viewAction {
        case .replyTapped(let reply):
            actionsSubject.send(.replyTapped(reply))
        case .openArweaveLink(let post):
            openArweaveLink(post)
        }
    }
    
    private func fetchFeed(_ feedId: String) {
        Task {
            let feedResult = await clientProxy.fetchFeedDetails(feedId: feedId)
            switch feedResult {
            case .success(let feed):
                state.bindings.feed = HomeScreenPost.init(post: feed)
            case .failure(let error):
                MXLog.error("Failed to fetch feed details: \(error)")
            }
        }
    }
    
    private func fetchFeedReplies(_ feedId: String) {
        guard !isFetchRepliesInProgress else { return }
        isFetchRepliesInProgress = true
        
        Task {
            defer { isFetchRepliesInProgress = false } // Ensure flag is reset when the task completes
            
            state.repliesListMode = state.feedReplies.isEmpty ? .skeletons : .replies
            let repliesResult = await clientProxy.fetchFeedReplies(feedId: feedId, limit: POST_REPLIES_PAGE_COUNT,
                                                                   skip: state.feedReplies.count)
            switch repliesResult {
            case .success(let replies):
                let hasNoReplies = replies.isEmpty
                if hasNoReplies {
                    state.repliesListMode = state.feedReplies.isEmpty ? .empty : .replies
                    state.canLoadMoreReplies = false
                } else {
                    var feedReplies: [HomeScreenPost] = state.feedReplies
                    for reply in replies {
                        let feedReply = HomeScreenPost(post: reply, rewardsDecimalPlaces: state.userRewards.decimals)
                        feedReplies.append(feedReply)
                    }
                    state.feedReplies = feedReplies
                    state.repliesListMode = .replies
                }
            case .failure(let error):
                MXLog.error("Failed to fetch zero post replies: \(error)")
                state.repliesListMode = state.feedReplies.isEmpty ? .empty : .replies
                switch error {
                case .postsLimitReached:
                    state.canLoadMoreReplies = false
                default:
                    displayError()
                }
            }
        }
    }
    
    private func displayError() {
        state.bindings.alertInfo = .init(id: UUID(),
                                         title: L10n.commonError,
                                         message: L10n.errorUnknown)
    }
    
    private func openArweaveLink(_ post: HomeScreenPost) {
        guard let arweaveUrl = post.getArweaveLink() else { return }
        UIApplication.shared.open(arweaveUrl)
    }
}
