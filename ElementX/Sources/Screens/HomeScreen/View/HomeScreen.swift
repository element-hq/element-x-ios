//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import Compound
import SwiftUI
import SwiftUIIntrospect

struct HomeScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isPresented) private var isPresented
    @ObservedObject var context: HomeScreenViewModel.Context
    
    @State private var scrollViewAdapter = ScrollViewAdapter()
    @State private var isSearching = false
    @State private var bloomView: UIView?
    @State private var bloomConstraints: [NSLayoutConstraint] = []
    @State private var leftBarButtonView: UIView?
    
    var body: some View {
        GeometryReader { geometry in
            ScrollView {
                switch context.viewState.roomListMode {
                case .skeletons:
                    LazyVStack(spacing: 0) {
                        ForEach(context.viewState.visibleRooms) { room in
                            HomeScreenRoomCell(room: room, context: context, isSelected: false)
                                .redacted(reason: .placeholder)
                        }
                    }
                    .shimmer()
                    .disabled(true)
                case .empty:
                    HomeScreenEmptyStateLayout(minHeight: geometry.size.height) {
                        topSection
                        
                        HomeScreenEmptyStateView(context: context)
                            .layoutPriority(1)
                    }
                case .rooms:
                    topSection
                    
                    LazyVStack(spacing: 0) {
                        HomeScreenRoomList(context: context, isSearching: $isSearching)
                    }
                    .searchable(text: $context.searchQuery)
                    .compoundSearchField()
                    .disableAutocorrection(true)
                }
            }
            .introspect(.scrollView, on: .iOS(.v16, .v17)) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .onReceive(scrollViewAdapter.didScroll) { _ in
                updateVisibleRange()
            }
            .onReceive(scrollViewAdapter.isScrolling) { _ in
                updateVisibleRange()
            }
            .onChange(of: context.searchQuery) { _ in
                updateVisibleRange()
            }
            .onChange(of: context.viewState.visibleRooms) { _ in
                updateVisibleRange()
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollDisabled(context.viewState.roomListMode == .skeletons)
            .scrollBounceBehavior(context.viewState.roomListMode == .empty ? .basedOnSize : .automatic)
            .animation(.elementDefault, value: context.viewState.showSessionVerificationBanner)
            .animation(.elementDefault, value: context.viewState.roomListMode)
            .animation(.none, value: context.viewState.visibleRooms)
        }
        .alert(item: $context.alertInfo)
        .alert(item: $context.leaveRoomAlertItem,
               actions: leaveRoomAlertActions,
               message: leaveRoomAlertMessage)
        .navigationTitle(L10n.screenRoomlistMainSpaceTitle)
        .toolbar { toolbar }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .track(screen: .home)
        .introspect(.viewController, on: .iOS(.v16, .v17)) { controller in
            Task {
                if bloomView == nil {
                    setBloomView(controller: controller)
                }
            }
            let isHidden = controller.navigationController?.topViewController != controller || isSearching
            bloomView?.isHidden = isHidden
            if !isHidden {
                updateBloomCenter()
            }
        }
    }
    
    // MARK: - Private
    
    private var bloomGradient: some View {
        LinearGradient(colors: [.clear, .compound.bgCanvasDefault], startPoint: .top, endPoint: .bottom)
            .mask {
                LinearGradient(colors: [.clear, .white], startPoint: .trailing, endPoint: .leading)
            }
            .ignoresSafeArea(edges: .all)
    }
            
    private func setBloomView(controller: UIViewController) {
        guard let navigationBarContainer = controller.navigationController?.navigationBar.subviews.first,
              let leftBarButtonView = controller.navigationItem.leadingItemGroups.first?.barButtonItems.first?.customView else {
            return
        }
        
        navigationBarContainer.clipsToBounds = true
        let hostingController = UIHostingController(rootView: bloom)
        hostingController.view.translatesAutoresizingMaskIntoConstraints = true
        hostingController.view.backgroundColor = .clear
        navigationBarContainer.insertSubview(hostingController.view, at: 0)
        self.leftBarButtonView = leftBarButtonView
        bloomView = hostingController.view
        updateBloomCenter()
        
        let gradientController = UIHostingController(rootView: bloomGradient)
        gradientController.view.backgroundColor = .clear
        gradientController.view.translatesAutoresizingMaskIntoConstraints = false
        navigationBarContainer.insertSubview(gradientController.view, aboveSubview: hostingController.view)
        
        let constraints = [gradientController.view.bottomAnchor.constraint(equalTo: navigationBarContainer.bottomAnchor),
                           gradientController.view.trailingAnchor.constraint(equalTo: navigationBarContainer.trailingAnchor),
                           gradientController.view.leadingAnchor.constraint(equalTo: navigationBarContainer.leadingAnchor),
                           gradientController.view.heightAnchor.constraint(equalToConstant: 30)]
        constraints.forEach { $0.isActive = true }
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
    
    @ViewBuilder
    /// The session verification banner and invites button if either are needed.
    private var topSection: some View {
        if context.viewState.showSessionVerificationBanner {
            sessionVerificationBanner
        }
        
        if context.viewState.hasPendingInvitations, !isSearching {
            HomeScreenInvitesButton(title: L10n.actionInvitesList, hasBadge: context.viewState.hasUnreadPendingInvitations) {
                context.send(viewAction: .selectInvites)
            }
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.invites)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.vertical, -8.0)
        }
    }
    
    private var sessionVerificationBanner: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    Text(L10n.sessionVerificationBannerTitle)
                        .font(.compound.bodyLGSemibold)
                        .foregroundColor(.compound.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        context.send(viewAction: .skipSessionVerification)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.compound.iconSecondary)
                            .frame(width: 12, height: 12)
                    }
                }
                Text(L10n.sessionVerificationBannerMessage)
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
            }
            
            Button(L10n.actionContinue) {
                context.send(viewAction: .verifySession)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.elementCapsuleProminent)
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.verificationBannerContinue)
        }
        .padding(16)
        .background(Color.compound.bgSubtleSecondary)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            HomeScreenUserMenuButton(context: context)
        }
        
        ToolbarItemGroup(placement: .primaryAction) {
            newRoomButton
        }
    }
    
    private var bloom: some View {
        ZStack {
            avatar
                .blur(radius: 64)
                .blendMode(.hardLight)
                .opacity(colorScheme == .dark ? 0.15 : 0.20)
            avatar
                .blur(radius: colorScheme == .dark ? 53 : 64)
                .blendMode(colorScheme == .dark ? .normal : .saturation)
                .opacity(colorScheme == .dark ? 0.20 : 0.75)
        }
    }
    
    private var avatar: some View {
        LoadableAvatarImage(url: context.viewState.userAvatarURL,
                            name: context.viewState.userDisplayName,
                            contentID: context.viewState.userID,
                            avatarSize: .custom(256),
                            imageProvider: context.imageProvider)
    }
    
    private var newRoomButton: some View {
        Button {
            context.send(viewAction: .startChat)
        } label: {
            Image(systemName: "square.and.pencil")
                .fontWeight(.semibold)
        }
        .accessibilityIdentifier(A11yIdentifiers.homeScreen.startChat)
    }
    
    /// Often times the scroll view's content size isn't correct yet when this method is called e.g. when cancelling a search
    /// Dispatch it with a delay to allow the UI to update and the computations to be correct
    /// Once we move to iOS 17 we should remove all of this and use scroll anchors instead
    private func updateVisibleRange() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { delayedUpdateVisibleRange() }
    }
    
    private func delayedUpdateVisibleRange() {
        guard let scrollView = scrollViewAdapter.scrollView,
              context.viewState.visibleRooms.count > 0 else {
            return
        }
        
        guard scrollView.contentSize.height > scrollView.bounds.height else {
            return
        }
        
        let adjustedContentSize = max(scrollView.contentSize.height - scrollView.contentInset.top - scrollView.contentInset.bottom, scrollView.bounds.height)
        let cellHeight = adjustedContentSize / Double(context.viewState.visibleRooms.count)
        
        let firstIndex = Int(max(0.0, scrollView.contentOffset.y + scrollView.contentInset.top) / cellHeight)
        let lastIndex = Int(max(0.0, scrollView.contentOffset.y + scrollView.bounds.height) / cellHeight)
        
        // This will be deduped and throttled on the view model layer
        context.send(viewAction: .updateVisibleItemRange(range: firstIndex..<lastIndex, isScrolling: scrollViewAdapter.isScrolling.value))
    }
    
    @ViewBuilder
    private func leaveRoomAlertActions(_ item: LeaveRoomAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle, role: .destructive) {
            context.send(viewAction: .confirmLeaveRoom(roomIdentifier: item.roomId))
        }
    }
    
    private func leaveRoomAlertMessage(_ item: LeaveRoomAlertItem) -> some View {
        Text(item.subtitle)
    }
}

// MARK: - Previews

struct HomeScreen_Previews: PreviewProvider {
    static let loadingViewModel = viewModel(.loading)
    static let loadedViewModel = viewModel(.loaded(.mockRooms))
    static let emptyViewModel = viewModel(.loaded([]))
    
    static var previews: some View {
        NavigationStack {
            HomeScreen(context: loadingViewModel.context)
        }
        .previewDisplayName("Loading")
        
        NavigationStack {
            HomeScreen(context: loadedViewModel.context)
        }
        .previewDisplayName("Loaded")
        
        NavigationStack {
            HomeScreen(context: emptyViewModel.context)
        }
        .previewDisplayName("Empty")
    }
    
    static func viewModel(_ state: MockRoomSummaryProviderState) -> HomeScreenViewModel {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@alice:example.com",
                                                                       roomSummaryProvider: MockRoomSummaryProvider(state: state)),
                                          mediaProvider: MockMediaProvider())
        
        return HomeScreenViewModel(userSession: userSession,
                                   attributedStringBuilder: AttributedStringBuilder(permalinkBaseURL: ServiceLocator.shared.settings.permalinkBaseURL),
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   appSettings: ServiceLocator.shared.settings,
                                   analytics: ServiceLocator.shared.analytics,
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
