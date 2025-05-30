//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias FeedUserProfileScreenViewModelType = StateStoreViewModel<FeedUserProfileScreenViewState, FeedUserProfileScreenViewAction>

class FeedUserProfileScreenViewModel: FeedUserProfileScreenViewModelType, FeedUserProfileScreenViewModelProtocol {
    
    private let clientProxy: ClientProxyProtocol
    private let feedUpdatedProtocol: FeedDetailsUpdatedProtocol?
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let mediaProvider: MediaProviderProtocol
    
    private let FEEDS_PAGE_COUNT = 10
    private var isFetchFeedsInProgress = false
    
    private var actionsSubject: PassthroughSubject<FeedUserProfileScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<FeedUserProfileScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         feedUpdatedProtocol: FeedDetailsUpdatedProtocol?,
         userIndicatorController: UserIndicatorControllerProtocol,
         userProfile: ZPostUserProfile) {
        self.clientProxy = clientProxy
        self.feedUpdatedProtocol = feedUpdatedProtocol
        self.userIndicatorController = userIndicatorController
        self.mediaProvider = mediaProvider
        
        super.init(initialViewState: .init(userID: userProfile.userId,
                                           userProfile: userProfile,
                                           shouldShowFollowButton: (clientProxy.userID.matrixIdToCleanHex() != userProfile.userId),
                                           bindings: .init()),
                   mediaProvider: mediaProvider)
        
        clientProxy.userRewardsPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userRewards, on: self)
            .store(in: &cancellables)
        
        fetchUserProfileData()
    }
    
    override func process(viewAction: FeedUserProfileScreenViewAction) {
        switch viewAction {
        case .feedTapped(let feed):
            let mediaUrl = state.userFeedsMediaInfoMap[feed.id]?.url
            let urlLinkPreview = state.userFeedsLinkPreviewsMap[feed.id]
            actionsSubject.send(.feedTapped(feed.withUpdatedData(url: mediaUrl, urlLinkPreview: urlLinkPreview)))
        case .openArweaveLink(let post):
            openArweaveLink(post)
        case .openYoutubeLink(let url):
            openYoutubeLink(url)
        case .loadMoreFeedsIfNeeded:
            fetchUserFeeds(state.userID)
//        case .forceRefreshFeeds:
//            fetchUserFeeds(state.userID, isForceRefresh: true)
        case .addMeowToPost(let postId, let amount):
            addMeowToPost(postId, amount)
        case .toggleFollowUser:
            toggleFollowUser()
        case .openDirectChat:
            openDirectChat()
        case .displayAvatar(let url):
            displayFullScreenAvatar(url)
        }
    }
    
    private func fetchUserProfileData() {
        Task {
            await(
                fetchUserProfile(),
                fetchUserFollowStatus(),
                fetchUserFeeds(state.userID)
            )
        }
    }
    
    private func fetchUserProfile() async {
        if let zid = state.userProfile.primaryZid, !zid.isEmpty {
            let result = await clientProxy.fetchFeedUserProfile(userZId: zid)
            switch result {
            case .success(let userProfile):
                state.userProfile = userProfile
            case .failure(let error):
                MXLog.error("Failed to fetch user profile for user: \(state.userID), with error: \(error)")
                displayError()
            }
        } else {
            state.shouldShowFollowButton = false
        }
    }
    
    private func fetchUserFollowStatus() async {
        let result = await clientProxy.fetchFeedUserFollowingStatus(userId: state.userID)
        switch result {
        case .success(let isFollowing):
            state.userFollowStatus = isFollowing
        case .failure(let error):
            MXLog.error("Failed to fetch user profile status for user: \(state.userID), with error: \(error)")
            displayError()
        }
    }
    
    private func fetchUserFeeds(_ userId: String, isForceRefresh: Bool = false) {
        guard !isFetchFeedsInProgress else { return }
        isFetchFeedsInProgress = true
        
        Task {
            defer { isFetchFeedsInProgress = false } // Ensure flag is reset when the task completes
            
            state.userFeedsListMode = state.userFeeds.isEmpty ? .empty : .feeds
            let skipItems = isForceRefresh ? 0 : state.userFeeds.count
            let feedsResult = await clientProxy.fetchUserFeeds(userId: userId,
                                                                 limit: FEEDS_PAGE_COUNT,
                                                                 skip: skipItems)
            switch feedsResult {
            case .success(let feeds):
                let hasNoFeeds = feeds.isEmpty
                if hasNoFeeds {
                    state.userFeedsListMode = state.userFeeds.isEmpty ? .empty : .feeds
                    state.canLoadMoreFeeds = false
                } else {
                    var userFeeds: [HomeScreenPost] = isForceRefresh ? [] : state.userFeeds
                    for feed in feeds {
                        let userFeed = HomeScreenPost(loggedInUserId: clientProxy.userID,
                                                       post: feed,
                                                       rewardsDecimalPlaces: state.userRewards.decimals)
                        userFeeds.append(userFeed)
                    }
                    state.userFeeds = userFeeds.uniqued(on: \.id)
                    state.userFeedsListMode = .feeds
                    loadFeedMediaInfo(for: state.userFeeds)
                    loadFeedLinkPreviews(for: state.userFeeds)
                }
            case .failure(let error):
                MXLog.error("Failed to fetch zero post replies: \(error)")
                state.userFeedsListMode = state.userFeeds.isEmpty ? .empty : .feeds
                switch error {
                case .postsLimitReached:
                    state.canLoadMoreFeeds = false
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
    
    private func openYoutubeLink(_ url: String) {
        guard let youtubeUrl = URL(string: url) else { return }
        UIApplication.shared.open(youtubeUrl)
    }
    
    private func addMeowToPost(_ postId: String, _ amount: Int) {
        Task {
            let addMeowResult = await clientProxy.addMeowsToFeed(feedId: postId, amount: amount)
            switch addMeowResult {
            case .success(let post):
                let homePost = HomeScreenPost(loggedInUserId: clientProxy.userID, post: post, rewardsDecimalPlaces: state.userRewards.decimals)
                if let index = state.userFeeds.firstIndex(where: { $0.id == homePost.id }) {
                    state.userFeeds[index] = homePost
                }
                feedUpdatedProtocol?.onFeedUpdated(postId)
            case .failure(let error):
                MXLog.error("Failed to add meow: \(error)")
                displayError()
            }
        }
    }
    
    private func loadFeedMediaInfo(for posts: [HomeScreenPost]) {
        Task {
            let postsToFetchMedia = posts.filter({ $0.mediaInfo != nil && state.userFeedsMediaInfoMap[$0.id] == nil })
            let results = await postsToFetchMedia.asyncMap { post in
                await clientProxy.getPostMediaInfo(mediaId: post.mediaInfo!.id)
            }
            for result in results {
                if case let .success(media) = result,
                   let postId = postsToFetchMedia.first(where: { $0.mediaInfo!.id == media.media.id })?.id {
                    state.userFeedsMediaInfoMap[postId] = HomeScreenPostMediaInfo(media: media)
                }
            }
        }
    }
    
    private func loadFeedLinkPreviews(for posts: [HomeScreenPost]) {
        Task {
            let postsToFetchLinkPreviews = posts.filter({
                LinkPreviewUtil.shared.firstAvailableYoutubeLink(from: $0.postText) != nil && state.userFeedsLinkPreviewsMap[$0.id] == nil
            })
            let results = await postsToFetchLinkPreviews.asyncMap { post in
                let url = LinkPreviewUtil.shared.firstAvailableYoutubeLink(from: post.postText)!
                let result = await clientProxy.fetchYoutubeLinkMetaData(youtubrUrl: url)
                return (post.id, result)
            }
            for result in results {
                if case let .success(linkPreview) = result.1 {
                    state.userFeedsLinkPreviewsMap[result.0] = linkPreview
                }
            }
        }
    }
    
    private func toggleFollowUser() {
        Task {
            let userIndicatorID = UUID().uuidString
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                                  type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                  title: "",
                                                                  persistent: true))
            let isFollowed = state.userFollowStatus?.isFollowing ?? false
            let result = if isFollowed {
                await clientProxy.unFollowFeedUser(userId: state.userID)
            } else {
                await clientProxy.followFeedUser(userId: state.userID)
            }
            switch result {
            case .success:
                fetchUserProfileData()
            case .failure(let error):
                MXLog.error("Failed to toggle user following state: \(state.userID), with error: \(error)")
                displayError()
            }
        }
    }
    
    private func openDirectChat() {
        guard let userId = state.userID.toMatrixUserIdFormat(ZeroContants.appServer.matrixHomeServerPostfix) else {
            return
        }
        Task {
            let userIndicatorID = UUID().uuidString
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                                  type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                  title: "",
                                                                  persistent: true))
            switch clientProxy.directRoomForUserID(userId) {
            case .success(let roomID):
                if let roomID {
                    actionsSubject.send(.openDirectChat(roomID))
                } else {
                    switch await clientProxy.createDirectRoom(with: userId, expectedRoomName: state.userProfile.firstName) {
                    case .success(let roomID):
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self.actionsSubject.send(.openDirectChat(roomID))
                        }
                    case .failure:
                        displayError()
                    }
                }
            case .failure:
                displayError()
            }
        }
    }
    
    private func displayFullScreenAvatar(_ url: URL) {
        if !url.isDummyURL() {
            let loadingIndicatorIdentifier = "roomAvatarLoadingIndicator"
            userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
            
            Task {
                defer {
                    userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
                }
                
                // We don't actually know the mime type here, assume it's an image.
                if let mediaSource = try? MediaSourceProxy(url: url, mimeType: "image/jpeg"),
                   case let .success(file) = await mediaProvider.loadFileFromSource(mediaSource) {
                    state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: state.userProfile.firstName)
                }
            }
        }
    }
}
