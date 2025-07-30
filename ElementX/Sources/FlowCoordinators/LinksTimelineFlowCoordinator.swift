//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI
import UIKit

class LinksTimelineFlowCoordinator: FlowCoordinatorProtocol {
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        // Not needed for this coordinator
    }
    
    func clearRoute(animated: Bool) {
        // Not needed for this coordinator
    }
    
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let roomProxy: JoinedRoomProxyProtocol
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    var completion: (() -> Void)?
    var onNavigateToMessage: ((String) -> Void)?
    
    init(navigationStackCoordinator: NavigationStackCoordinator,
         roomProxy: JoinedRoomProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.navigationStackCoordinator = navigationStackCoordinator
        self.roomProxy = roomProxy
        self.mediaProvider = mediaProvider
        self.userIndicatorController = userIndicatorController
    }
    
    func start() {
        let viewModel = LinksTimelineScreenViewModel(
            roomProxy: roomProxy,
            mediaProvider: mediaProvider,
            userIndicatorController: userIndicatorController
        )
        
        viewModel.actions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] action in
                self?.handleAction(action)
            }
            .store(in: &cancellables)
        
        // Handle view actions through the view model's actions
        // View actions are handled by the view model itself
        
        let view = LinksTimelineScreen(context: viewModel.context)
        let coordinator = LinksTimelineScreenCoordinator(view: view)
        
        navigationStackCoordinator.setSheetCoordinator(coordinator) { [weak self] in
            self?.completion?()
        }
    }
    
    private func handleAction(_ action: LinksTimelineScreenViewModelAction) {
        switch action {
        case .openURL(let url):
            // Ensure URL has a valid scheme
            var finalURL = url
            if url.scheme == nil {
                // If no scheme, assume it's a website and add https://
                if let urlWithScheme = URL(string: "https://" + url.absoluteString) {
                    finalURL = urlWithScheme
                }
            }
            
            // Try to open the URL
            if UIApplication.shared.canOpenURL(finalURL) {
                UIApplication.shared.open(finalURL)
            } else {
                // Fallback: try to open with https if it was http
                if finalURL.scheme == "http", let httpsURL = URL(string: finalURL.absoluteString.replacingOccurrences(of: "http://", with: "https://")) {
                    UIApplication.shared.open(httpsURL)
                }
            }
        case .shareURL(let url):
            let activityViewController = UIActivityViewController(activityItems: [url], applicationActivities: nil)
            
            if let topViewController = UIApplication.shared.windows.first?.rootViewController?.topMostViewController() {
                topViewController.present(activityViewController, animated: true)
            }
        case .navigateToMessage(let eventID):
            print("DEBUG: Coordinator received navigateToMessage action with eventID: \(eventID)")
            // Close the links timeline screen
            navigationStackCoordinator.setSheetCoordinator(nil)
            // Call the callback to navigate to the specific message
            print("DEBUG: Calling onNavigateToMessage callback")
            onNavigateToMessage?(eventID)
        case .close:
            navigationStackCoordinator.setSheetCoordinator(nil)
        }
    }
}

// MARK: - LinksTimelineScreenCoordinator

class LinksTimelineScreenCoordinator: CoordinatorProtocol {
    private let view: LinksTimelineScreen
    
    init(view: LinksTimelineScreen) {
        self.view = view
    }
    
    func start() {
        // Coordinator is already started when created
    }
    
    func toPresentable() -> AnyView {
        AnyView(view)
    }
}

// MARK: - Extensions

extension UIViewController {
    func topMostViewController() -> UIViewController {
        if let presented = presentedViewController {
            return presented.topMostViewController()
        }
        
        if let navigation = self as? UINavigationController {
            return navigation.visibleViewController?.topMostViewController() ?? navigation
        }
        
        if let tab = self as? UITabBarController {
            return tab.selectedViewController?.topMostViewController() ?? tab
        }
        
        return self
    }
} 
