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
    private let feedUpdatedProtocol: FeedDetailsUpdatedProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private let POST_REPLIES_PAGE_COUNT = 10
    private var isFetchRepliesInProgress = false
    
    private var currentUserWalletAddress: String? = nil
    private var defaultChannelZId: String? = nil
    
    private var actionsSubject: PassthroughSubject<FeedDetailsScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<FeedDetailsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         feedUpdatedProtocol: FeedDetailsUpdatedProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         feedItem: HomeScreenPost) {
        self.clientProxy = userSession.clientProxy
        self.feedUpdatedProtocol = feedUpdatedProtocol
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(userID: clientProxy.userID, bindings: .init(feed: feedItem)), mediaProvider: userSession.mediaProvider)
        
        userSession.clientProxy.userRewardsPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userRewards, on: self)
            .store(in: &cancellables)
        
        clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
        clientProxy.zeroCurrentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.currentUserWalletAddress = currentUser.thirdWebWalletAddress
                self?.defaultChannelZId = currentUser.primaryZID
            }
            .store(in: &cancellables)
        
        fetchFeed(feedItem.id)
        fetchFeedReplies(feedItem.id)
    }
    
    override func process(viewAction: FeedDetailsScreenViewAction) {
        switch viewAction {
        case .replyTapped(let reply):
            let mediaUrl = state.postRepliesMediaInfoMap[reply.id]?.url
            actionsSubject.send(.replyTapped(reply.withUpdatedMediaInfoUrl(url: mediaUrl)))
        case .openArweaveLink(let post):
            openArweaveLink(post)
        case .loadMoreRepliesIfNeeded:
            fetchFeedReplies(state.bindings.feed.id)
        case .forceRefreshFeed:
            forceRefreshFeed()
        case .meowTapped(let postId, let amount, let isPostAReply):
            addMeowToPost(postId, amount, isPostAReply: isPostAReply)
        case .postReply:
            postFeedReply()
        }
    }
    
    private func fetchFeed(_ feedId: String) {
        Task {
            let feedResult = await clientProxy.fetchFeedDetails(feedId: feedId)
            switch feedResult {
            case .success(let feed):
                let homePost = HomeScreenPost.init(loggedInUserId: clientProxy.userID, post: feed)
                state.bindings.feed = homePost.withUpdatedMediaInfo(mediaInfo: state.bindings.feed.mediaInfo)
            case .failure(let error):
                MXLog.error("Failed to fetch feed details: \(error)")
            }
        }
    }
    
    private func fetchFeedReplies(_ feedId: String, isForceRefresh: Bool = false) {
        guard !isFetchRepliesInProgress else { return }
        isFetchRepliesInProgress = true
        
        Task {
            defer { isFetchRepliesInProgress = false } // Ensure flag is reset when the task completes
            
            state.repliesListMode = state.feedReplies.isEmpty ? .skeletons : .replies
            let skipItems = isForceRefresh ? 0 : state.feedReplies.count
            let repliesResult = await clientProxy.fetchFeedReplies(feedId: feedId, limit: POST_REPLIES_PAGE_COUNT,
                                                                   skip: skipItems)
            switch repliesResult {
            case .success(let replies):
                let hasNoReplies = replies.isEmpty
                if hasNoReplies {
                    state.repliesListMode = state.feedReplies.isEmpty ? .empty : .replies
                    state.canLoadMoreReplies = false
                } else {
                    var feedReplies: [HomeScreenPost] = isForceRefresh ? [] : state.feedReplies
                    for reply in replies {
                        let feedReply = HomeScreenPost(loggedInUserId: clientProxy.userID,
                                                       post: reply,
                                                       rewardsDecimalPlaces: state.userRewards.decimals)
                        feedReplies.append(feedReply)
                    }
                    state.feedReplies = feedReplies.uniqued(on: \.id)
                    state.repliesListMode = .replies
                    loadPostRepliesMediaInfo(for: state.feedReplies)
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
    
    private func forceRefreshFeed() {
        let feedId = state.bindings.feed.id
        fetchFeed(feedId)
        fetchFeedReplies(feedId, isForceRefresh: true)
    }
    
    private func addMeowToPost(_ postId: String, _ amount: Int, isPostAReply: Bool) {
        Task {
            let addMeowResult = await clientProxy.addMeowsToFeed(feedId: postId, amount: amount)
            switch addMeowResult {
            case .success(let post):
                let homePost = HomeScreenPost(loggedInUserId: clientProxy.userID, post: post, rewardsDecimalPlaces: state.userRewards.decimals)
                if isPostAReply {
                    if let index = state.feedReplies.firstIndex(where: { $0.id == homePost.id }) {
                        state.feedReplies[index] = homePost
                    }
                } else {
                    state.bindings.feed = homePost
                }
                feedUpdatedProtocol.onFeedUpdated(postId)
            case .failure(let error):
                MXLog.error("Failed to add meow: \(error)")
                displayError()
            }
        }
    }
    
    private func postFeedReply() {
//        guard let userWalletAddress = currentUserWalletAddress else {
//            state.bindings.alertInfo = .init(id: UUID(),
//                                             title: L10n.commonError,
//                                             message: "User default wallet is not initialized.")
//            return
//        }
        guard let defaultChannelZId = defaultChannelZId else {
            state.bindings.alertInfo = .init(id: UUID(),
                                             title: L10n.commonError,
                                             message: "Please set user primaryZId in profile settings.")
            return
        }
        
        Task {
            let userIndicatorID = UUID().uuidString
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                                  type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                  title: "Posting...",
                                                                  persistent: true))
            
            let postFeedResult = await clientProxy.postNewFeed(channelZId: defaultChannelZId,
                                                               content: state.bindings.myPostReply,
                                                               replyToPost: state.bindings.feed.id)
            switch postFeedResult {
            case .success(_):
                state.bindings.myPostReply = ""
                forceRefreshFeed()
                feedUpdatedProtocol.onFeedUpdated(state.bindings.feed.id)
            case .failure(_):
                state.bindings.alertInfo = .init(id: UUID(),
                                                 title: L10n.commonError,
                                                 message: L10n.errorUnknown)
            }
        }
    }
    
    private func loadPostRepliesMediaInfo(for posts: [HomeScreenPost]) {
        Task {
            let postsToFetchMedia = posts.filter({ $0.mediaInfo != nil && state.postRepliesMediaInfoMap[$0.id] == nil })
            let results = await postsToFetchMedia.asyncMap { post in
                await clientProxy.getPostMediaInfo(mediaId: post.mediaInfo!.id)
            }
            for result in results {
                if case let .success(media) = result,
                   let postId = postsToFetchMedia.first(where: { $0.mediaInfo!.id == media.media.id })?.id {
                    state.postRepliesMediaInfoMap[postId] = HomeScreenPostMediaInfo(media: media)
                }
            }
        }
    }
}
