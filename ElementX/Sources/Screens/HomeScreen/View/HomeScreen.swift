//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SentrySwiftUI
import SwiftUI

struct HomeScreen: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    
    @State private var scrollViewAdapter = ScrollViewAdapter()
    
    @State private var selectedTab: HomeTab = .chat
    @State private var showBackToTop = false
    @State private var hideNavigationBar = false
    
    //    init(context: HomeScreenViewModel.Context) {
    //        self.context = context
    //
    //        let appearance = UINavigationBarAppearance()
    //        appearance.configureWithTransparentBackground()
    //        appearance.backgroundEffect = UIBlurEffect(style: .regular)
    //        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.15)
    //
    //        UINavigationBar.appearance().standardAppearance = appearance
    //        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    //    }
    
    var body: some View {
        ZStack(alignment: .top) {
            HomeTabView(
                tabContent: { tab in
                    switch tab {
                    case .chat:
                        HomeScreenContent(context: context, scrollViewAdapter: scrollViewAdapter)
                    case .channels:
                        HomeChannelsContent(context: context, scrollViewAdapter: scrollViewAdapter)
                    case .feed:
                        HomePostsContent(context: context, scrollViewAdapter: scrollViewAdapter)
                    case .notifications:
                        HomeNotificationsContent(context: context, scrollViewAdapter: scrollViewAdapter)
                    case .myFeed:
                        HomeMyPostsContent(context: context, scrollViewAdapter: scrollViewAdapter)
                    case .wallet:
                        HomeWalletContent(context: context)
                    }
                },
                onTabSelected: { tab in
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        showBackToTop = false
                        hideNavigationBar = false
                        context.send(viewAction: .onHomeTabChanged)
                    }
                    selectedTab = tab
                },
                hasNewNotifications: context.viewState.hasNewNotificatios,
                isTabViewVisible: !context.isSearchFieldFocused
            )
            .onReceive(scrollViewAdapter.isAtTopEdge) { isAtTop in
                if showBackToTop == isAtTop {
                    return
                }
                withAnimation(.easeInOut(duration: 0.3)) {
                    showBackToTop = isAtTop
                }
            }
            .onReceive(scrollViewAdapter.scrollDirection) { direction in
                let shouldHideNavBar = scrollViewAdapter.isAtTopEdge.value && direction == .down
                
                guard shouldHideNavBar != hideNavigationBar else { return }
                
                withAnimation(.easeInOut(duration: 0.3)) {
                    hideNavigationBar = shouldHideNavBar
                }
            }
            
            // Top gradient overlay when nav bar is hidden
            if hideNavigationBar {
                topBarGradientOverlay
            }
            
            if showBackToTop {
                backToTopButton
            }
        }
        .alert(item: $context.alertInfo)
        .alert(item: $context.leaveRoomAlertItem,
               actions: leaveRoomAlertActions,
               message: leaveRoomAlertMessage)
        //            .navigationTitle(L10n.screenRoomlistMainSpaceTitle)
        .toolbar { toolbar }
        .navigationBarHidden(hideNavigationBar)
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .track(screen: .Home)
        //            .bloom(context: context,
        //                   scrollViewAdapter: scrollViewAdapter,
        //                   isNewBloomEnabled: context.viewState.isNewBloomEnabled)
        .sentryTrace("\(Self.self)")
        .quickLookPreview($context.mediaPreviewItem)
        .sheet(isPresented: $context.showEarningsClaimedSheet) {
            ClaimedEarningsSheetView(
                state: context.viewState.claimRewardsState,
                userRewards: context.viewState.userRewards,
                onDismiss: {
                    context.send(viewAction: .claimRewards(trigger: false))
                },
                onRetryClaim: {
                    context.send(viewAction: .claimRewards(trigger: true))
                },
                onViewClaimTransaction: { transactionId in
                    //view transaction here
                }
            )
            .presentationDetents([.height(400)])
            .presentationDragIndicator(.hidden)
        }
    }
    
    // MARK: - Private
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                context.send(viewAction: .showSettings)
            } label: {
                ZStack {
                    if context.viewState.showNewUserRewardsIntimation {
                        ZStack(alignment: .center) {
                            Circle().stroke(Color.zero.bgAccentRest.opacity(0.5), lineWidth: 1)
                                .frame(width: 38, height: 38)
                            Circle().stroke(Color.zero.bgAccentRest, lineWidth: 1)
                                .frame(width: 35, height: 35)
                        }
                        .task {
                            context.send(viewAction: .rewardsIntimated)
                        }
                    }
                    
                    LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                        name: context.viewState.userDisplayName,
                                        contentID: context.viewState.userID,
                                        avatarSize: .user(on: .home),
                                        mediaProvider: context.mediaProvider,
                                        onTap: { _ in
                        context.send(viewAction: .showSettings)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
                    .overlayBadge(10, isBadged: context.viewState.requiresExtraAccountSetup)
                    .compositingGroup()
                    .overlay {
                        if context.viewState.showNewUserRewardsIntimation {
                            userRewardsToolTip
                                .offset(x: 85, y: 45)
                                .allowsHitTesting(false)
                        }
                    }
                }
            }
            .accessibilityLabel(L10n.commonSettings)
        }
        
        ToolbarItem(placement: .principal) {
            Image(asset: Asset.Images.zeroWordmark)
        }
        
        ToolbarItem(placement: .primaryAction) {
            userProfileButton
        }
    }
    
    @ViewBuilder
    private var userProfileButton: some View {
        Button {
            context.send(viewAction: .openUserProfile)
        } label: {
            Image(asset: Asset.Images.homeTabProfileIcon)
                .tint(.compound.iconSecondary)
        }
        .accessibilityLabel("action_user_profile")
        .accessibilityIdentifier("action_user_profile")
    }
    
    @ViewBuilder
    private var backToTopButton: some View {
        Button(action: {
            scrollViewAdapter.scrollToTop()
        }) {
            HStack {
                Text("Back to Top")
                    .font(.zero.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                
                Image(systemName: "arrow.up")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.compound.textSecondary)
                    .padding(.horizontal, 2)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(.compound.bgCanvasDefault)
            .clipShape(RoundedRectangle(cornerRadius: 32))
        }
        .frame(maxWidth: .infinity)
        .transition(.opacity.combined(with:.scale))
        .padding(.top, 16)
    }
    
    @ViewBuilder
    private var topBarGradientOverlay: some View {
        LinearGradient(
            gradient: Gradient(colors: [.black, .clear, .clear]),
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 200)
        .ignoresSafeArea(edges: .top)
        .transition(.opacity)
        .allowsHitTesting(false)
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
    
    private var userRewardsToolTip: some View {
        Button {
            context.send(viewAction: .rewardsIntimated)
        } label: {
            VStack(alignment: .leading, spacing: 0) {
                Triangle()
                    .fill(.ultraThickMaterial)
                    .frame(width: 25, height: 15)
                    .padding(.leading, 16)
                
                HStack {
                    Text("You earned $\(context.viewState.userRewards.getRefPriceFormatted())")
                        .font(.inter(size: 16))
                    
                    Spacer()
                    
                    CompoundIcon(\.close)
                }
                .padding(.all, 16)
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
        }
        .allowsHitTesting(false)
        .frame(width: 225, height: 30, alignment: .leading)
    }
    
    private struct Triangle: Shape {
        func path(in rect: CGRect) -> Path {
            var path = Path()
            // Define the three points of the triangle
            path.move(to: CGPoint(x: rect.midX, y: rect.minY)) // Top middle
            path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY)) // Bottom right
            path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY)) // Bottom left
            path.closeSubpath()
            return path
        }
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
        .snapshotPreferences(expect: loadedViewModel.context.$viewState.map { state in
            state.roomListMode == .skeletons
        })
        .previewDisplayName("Loading")
        
        NavigationStack {
            HomeScreen(context: emptyViewModel.context)
        }
        .snapshotPreferences(expect: emptyViewModel.context.$viewState.map { state in
            state.roomListMode == .empty
        })
        .previewDisplayName("Empty")
        
        NavigationStack {
            HomeScreen(context: loadedViewModel.context)
        }
        .snapshotPreferences(expect: loadedViewModel.context.$viewState.map { state in
            state.roomListMode == .rooms
        })
        .previewDisplayName("Loaded")
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
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   appSettings: ServiceLocator.shared.settings,
                                   analyticsService: ServiceLocator.shared.analytics,
                                   notificationManager: NotificationManagerMock(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
