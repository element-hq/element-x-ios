//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Compound
import SwiftUI
import SwiftUIIntrospect

struct HomeScreen: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    
    @State private var scrollViewAdapter = ScrollViewAdapter()
    
    // Bloom components
    @State private var bloomView: UIView?
    @State private var leftBarButtonView: UIView?
    @State private var gradientView: UIView?
    @State private var navigationBarContainer: UIView?
    @State private var hairlineView: UIView?
    
    var body: some View {
        HomeScreenContent(context: context, scrollViewAdapter: scrollViewAdapter)
            .alert(item: $context.alertInfo)
            .alert(item: $context.leaveRoomAlertItem,
                   actions: leaveRoomAlertActions,
                   message: leaveRoomAlertMessage)
            .navigationTitle(L10n.screenRoomlistMainSpaceTitle)
            .toolbar { toolbar }
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .track(screen: .Home)
            .introspect(.viewController, on: .supportedVersions) { controller in
                Task {
                    if bloomView == nil {
                        makeBloomView(controller: controller)
                    }
                }
                let isTopController = controller.navigationController?.topViewController != controller
                let isHidden = isTopController || context.isSearchFieldFocused
                if let bloomView {
                    bloomView.isHidden = isHidden
                    UIView.transition(with: bloomView, duration: 1.75, options: .curveEaseInOut) {
                        bloomView.alpha = isTopController ? 0 : 1
                    }
                }
                gradientView?.isHidden = isHidden
                navigationBarContainer?.clipsToBounds = !isHidden
                hairlineView?.isHidden = isHidden || !scrollViewAdapter.isAtTopEdge.value
                if !isHidden {
                    updateBloomCenter()
                }
            }
            .onReceive(scrollViewAdapter.isAtTopEdge.removeDuplicates()) { value in
                hairlineView?.isHidden = !value
                guard let gradientView else {
                    return
                }
                if value {
                    UIView.transition(with: gradientView, duration: 0.3, options: .curveEaseIn) {
                        gradientView.alpha = 0
                    }
                } else {
                    gradientView.alpha = 1
                }
            }
            .sentryTrace("\(Self.self)")
    }
    
    // MARK: - Private
    
    private var bloomGradient: some View {
        LinearGradient(colors: [.clear, .compound.bgCanvasDefault], startPoint: .top, endPoint: .bottom)
            .mask {
                LinearGradient(stops: [.init(color: .white, location: 0.75), .init(color: .clear, location: 1.0)],
                               startPoint: .leading,
                               endPoint: .trailing)
            }
            .ignoresSafeArea(edges: .all)
    }
            
    private func makeBloomView(controller: UIViewController) {
        guard let navigationBarContainer = controller.navigationController?.navigationBar.subviews.first,
              let leftBarButtonView = controller.navigationItem.leadingItemGroups.first?.barButtonItems.first?.customView else {
            return
        }
        
        let bloomController = UIHostingController(rootView: bloom)
        bloomController.view.translatesAutoresizingMaskIntoConstraints = true
        bloomController.view.backgroundColor = .clear
        navigationBarContainer.insertSubview(bloomController.view, at: 0)
        self.leftBarButtonView = leftBarButtonView
        bloomView = bloomController.view
        self.navigationBarContainer = navigationBarContainer
        updateBloomCenter()
        
        let gradientController = UIHostingController(rootView: bloomGradient)
        gradientController.view.backgroundColor = .clear
        gradientController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationBarContainer.insertSubview(gradientController.view, aboveSubview: bloomController.view)
        
        let constraints = [gradientController.view.bottomAnchor.constraint(equalTo: navigationBarContainer.bottomAnchor),
                           gradientController.view.trailingAnchor.constraint(equalTo: navigationBarContainer.trailingAnchor),
                           gradientController.view.leadingAnchor.constraint(equalTo: navigationBarContainer.leadingAnchor),
                           gradientController.view.heightAnchor.constraint(equalToConstant: 40)]
        constraints.forEach { $0.isActive = true }
        gradientView = gradientController.view
        
        let dividerController = UIHostingController(rootView: Divider().ignoresSafeArea())
        dividerController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationBarContainer.addSubview(dividerController.view)
        let dividerConstraints = [dividerController.view.bottomAnchor.constraint(equalTo: gradientController.view.bottomAnchor),
                                  dividerController.view.widthAnchor.constraint(equalTo: gradientController.view.widthAnchor),
                                  dividerController.view.leadingAnchor.constraint(equalTo: gradientController.view.leadingAnchor)]
        dividerConstraints.forEach { $0.isActive = true }
        hairlineView = dividerController.view
    }

    private func updateBloomCenter() {
        guard let leftBarButtonView,
              let bloomView,
              let navigationBarContainer = bloomView.superview else {
            return
        }
        
        let center = leftBarButtonView.convert(leftBarButtonView.center, to: navigationBarContainer.coordinateSpace)
        bloomView.center = center
    }
        
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                context.send(viewAction: .showSettings)
            } label: {
                LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                    name: context.viewState.userDisplayName,
                                    contentID: context.viewState.userID,
                                    avatarSize: .user(on: .home),
                                    mediaProvider: context.mediaProvider)
                    .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
                    .overlayBadge(10, isBadged: context.viewState.requiresExtraAccountSetup)
                    .compositingGroup()
            }
            .accessibilityLabel(L10n.commonSettings)
        }
        
        ToolbarItem(placement: .primaryAction) {
            newRoomButton
        }
    }
    
    private var bloom: some View {
        BloomView(context: context)
    }
    
    @ViewBuilder
    private var newRoomButton: some View {
        switch context.viewState.roomListMode {
        case .empty, .rooms:
            Button {
                context.send(viewAction: .startChat)
            } label: {
                CompoundIcon(\.compose)
            }
            .accessibilityLabel(L10n.actionStartChat)
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.startChat)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private func leaveRoomAlertActions(_ item: LeaveRoomAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle, role: .destructive) {
            context.send(viewAction: .confirmLeaveRoom(roomIdentifier: item.roomID))
        }
    }
    
    private func leaveRoomAlertMessage(_ item: LeaveRoomAlertItem) -> some View {
        Text(item.subtitle)
    }
}

// MARK: - Previews

struct HomeScreen_Previews: PreviewProvider, TestablePreview {
    static let loadingViewModel = viewModel(.skeletons)
    static let emptyViewModel = viewModel(.empty)
    static let loadedViewModel = viewModel(.rooms)
    
    static var previews: some View {
        NavigationStack {
            HomeScreen(context: loadingViewModel.context)
        }
        .previewDisplayName("Loading")
        
        NavigationStack {
            HomeScreen(context: emptyViewModel.context)
        }
        .previewDisplayName("Empty")
        .snapshotPreferences(delay: 4.0)
        
        NavigationStack {
            HomeScreen(context: loadedViewModel.context)
        }
        .previewDisplayName("Loaded")
        .snapshotPreferences(delay: 4.0)
    }
    
    static func viewModel(_ mode: HomeScreenRoomListMode) -> HomeScreenViewModel {
        let userID = "@alice:example.com"
        
        let roomSummaryProviderState: RoomSummaryProviderMockConfigurationState = switch mode {
        case .skeletons:
            .loading
        case .empty:
            .loaded([])
        case .rooms:
            .loaded(.mockRooms)
        }
        
        let clientProxy = ClientProxyMock(.init(userID: userID,
                                                roomSummaryProvider: RoomSummaryProviderMock(.init(state: roomSummaryProviderState))))
        
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        return HomeScreenViewModel(userSession: userSession,
                                   analyticsService: ServiceLocator.shared.analytics,
                                   appSettings: ServiceLocator.shared.settings,
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
