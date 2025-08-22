//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation

enum UserFeedProfileFlowCoordinatorAction {
    case finished
    case presentMatrixProfile
    case presentFeedDetails(feed: HomeScreenPost)
    case openDirectChat(_ roomId: String)
}

class UserFeedProfileFlowCoordinator: FlowCoordinatorProtocol {
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let userSession: UserSessionProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let fromHomeFlow: Bool
    private let appMediator: AppMediatorProtocol
    
    private let userId: String
    private var userFeedProfile: ZPostUserProfile?
    private let feedProtocol: FeedProtocol?
    
    private let actionsSubject: PassthroughSubject<UserFeedProfileFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<UserFeedProfileFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(navigationStackCoordinator: NavigationStackCoordinator,
         userSession: UserSessionProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         appMediator: AppMediatorProtocol,
         fromHomeFlow: Bool,
         userId: String,
         userFeedProfile: ZPostUserProfile?,
         feedProtocol: FeedProtocol?) {
        self.navigationStackCoordinator = navigationStackCoordinator
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController
        self.appMediator = appMediator
        self.fromHomeFlow = fromHomeFlow

        self.userId = userId
        self.userFeedProfile = userFeedProfile
        self.feedProtocol = feedProtocol
    }
    
    func start() {
        Task { await presentUserFeedProfileScreen() }
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError()
    }
    
    func clearRoute(animated: Bool) {
        fatalError()
    }
    
    private func presentUserFeedProfileScreen() async {
        var userFeedProfile = self.userFeedProfile
        // Load user profile if empty
        if userFeedProfile == nil {
            showLoadingIndicator()
            let profile = await userSession.clientProxy.profile(for: userId)
            switch profile {
            case .success(let userProfile):
                hideLoadingIndicator()
                userFeedProfile = userProfile.toZeroFeedProfile()
                self.userFeedProfile = userFeedProfile
            case .failure(let error):
                hideLoadingIndicator()
                MXLog.error("Failed to fetch user profile for user \(userId), with error: \(error)")
//                actionsSubject.send(.presentMatrixProfile)
            }
        }
        guard let userFeedProfile else {
//            actionsSubject.send(.presentMatrixProfile)
            return
        }
        
        let stackCoordinator = NavigationStackCoordinator()
        let profileCoordinator = FeedUserProfileScreenCoordinator(parameters: .init(userSession: userSession,
                                                                                    feedProtocol: feedProtocol,
                                                                                    userProfile: userFeedProfile))
        profileCoordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .feedTapped(let feed):
//                    if fromHomeFlow {
//                        navigationStackCoordinator.setSheetCoordinator(nil)
//                        actionsSubject.send(.presentFeedDetails(feed: feed))
//                    } else {
//                        presentFeedDetailsScreen(feed, feedProtocol: feedProtocol, stackCoordinator: stackCoordinator)
//                    }
                    presentFeedDetailsScreen(feed, feedProtocol: feedProtocol, stackCoordinator: stackCoordinator)
                case .openDirectChat(let roomId):
                    navigationStackCoordinator.setSheetCoordinator(nil)
                    actionsSubject.send(.openDirectChat(roomId))
                case .newFeed(let createFeedProtocol):
                    presentCreateFeedScreen(createFeedProtocol, stackCoordinator: stackCoordinator)
                }
            }
            .store(in: &cancellables)
        stackCoordinator.setRootCoordinator(profileCoordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.actionsSubject.send(.finished)
        }
    }
    
    private func presentFeedDetailsScreen(_ post: HomeScreenPost,
                                          feedProtocol: FeedProtocol?,
                                          isChildFeed: Bool = false,
                                          stackCoordinator: NavigationStackCoordinator) {
        let parameters = FeedDetailsScreenCoordinatorParameters(userSession: userSession,
                                                                feedProtocol: feedProtocol,
                                                                feedItem: post,
                                                                isFeedDetailsRefreshable: true)
        let coordinator = FeedDetailsScreenCoordinator(parameters: parameters)
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .replyTapped(let reply):
                    presentFeedDetailsScreen(reply, feedProtocol: feedProtocol, isChildFeed: true, stackCoordinator: stackCoordinator)
                case .attachMedia(let attachMediaProtocol):
                    presentMediaUploadPickerWithSource(attachMediaProtocol, stackCoordinator: stackCoordinator)
                case .openPostUserProfile( _):
                    break
                }
            }
            .store(in: &cancellables)
        stackCoordinator.push(coordinator)
    }
    
    private func presentMediaUploadPickerWithSource(_ attachMediaProtocol: FeedMediaSelectedProtocol,
                                                    stackCoordinator: NavigationStackCoordinator) {
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(mode: .init(source: .photoLibrary, selectionType: .single),
                                                                  userIndicatorController: userIndicatorController,
                                                                  orientationManager: appMediator.windowManager) { [weak self] action in
            guard let self else {
                return
            }
            switch action {
            case .cancel:
                stackCoordinator.pop()
            case .selectedMediaAtURLs(let urls):
                if let url = urls.first {
                    attachMediaProtocol.onMediaSelected(media: url)
                    stackCoordinator.pop()
                }
            }
        }
        stackCoordinator.push(mediaPickerCoordinator)
    }
    
    private func presentCreateFeedScreen(_ feedProtocol: FeedProtocol,
                                         stackCoordinator: NavigationStackCoordinator) {
        let coordinator = CreateFeedScreenCoordinator(parameters: .init(userSession: userSession,
                                                                        feedProtocol: feedProtocol,
                                                                        fromUserProfileFlow: true))
        coordinator.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .newPostCreated:
                    feedProtocol.onNewFeedPosted()
                    stackCoordinator.pop()
                case .dismissPost:
                    stackCoordinator.pop()
                case .attachMedia(let attachMediaProtocol):
                    presentMediaUploadPickerWithSource(attachMediaProtocol, stackCoordinator: stackCoordinator)
                }
            }
            .store(in: &cancellables)
        
        stackCoordinator.push(coordinator)
    }
    
    private static let loadingIndicatorID = "\(UserFeedProfileFlowCoordinator.self)-Loading"
    
    private func showLoadingIndicator(delay: Duration? = nil) {
        userIndicatorController.submitIndicator(.init(id: Self.loadingIndicatorID,
                                                      type: .modal(progress: .indeterminate,
                                                                   interactiveDismissDisabled: false,
                                                                   allowsInteraction: false),
                                                      title: L10n.commonLoading, persistent: true),
                                                delay: delay)
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorID)
    }
}
