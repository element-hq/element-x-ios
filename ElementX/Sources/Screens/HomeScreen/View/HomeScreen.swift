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
    
    init(context: HomeScreenViewModel.Context) {
        self.context = context
        
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundEffect = UIBlurEffect(style: .regular)
        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.15)
        
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        Group {
            if selectedTab == .chat, context.manualSearchTriggered {
                HomeScreenContent(context: context, scrollViewAdapter: scrollViewAdapter)
            } else {
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
                        }
                    },
                    onTabSelected: { tab in
                        selectedTab = tab
                    }
                )
            }
        }
            .alert(item: $context.alertInfo)
            .alert(item: $context.leaveRoomAlertItem,
                   actions: leaveRoomAlertActions,
                   message: leaveRoomAlertMessage)
//            .navigationTitle(L10n.screenRoomlistMainSpaceTitle)
            .toolbar { toolbar }
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .track(screen: .Home)
            .bloom(context: context,
                   scrollViewAdapter: scrollViewAdapter,
                   isNewBloomEnabled: context.viewState.isNewBloomEnabled)
            .sentryTrace("\(Self.self)")
    }
    
    // MARK: - Private
        
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button {
                context.send(viewAction: .showSettings)
            } label: {
                HStack {
                    LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                        name: context.viewState.userDisplayName,
                                        contentID: context.viewState.userID,
                                        avatarSize: .user(on: .home),
                                        mediaProvider: context.mediaProvider)
                        .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
                        .overlayBadge(10, isBadged: context.viewState.requiresExtraAccountSetup)
                        .compositingGroup()
                        .overlay {
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
                                
                                userRewardsToolTip
                                    .offset(x: 85, y: 45)
                            }
                        }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(context.viewState.userDisplayName ?? "")
                            .font(.zero.bodyMD)
                            .foregroundColor(.compound.textPrimary)
                        if context.viewState.primaryZeroId != nil {
                            Text(context.viewState.primaryZeroId!)
                                .font(.zero.bodyXS)
                                .foregroundColor(.compound.textSecondary)
                        }
                    }
                }
            }
            .accessibilityLabel(L10n.commonSettings)
        }
        
        ToolbarItem(placement: .primaryAction) {
            switch selectedTab {
            case .chat:
                newRoomButton
            case .feed, .myFeed:
                newFeedButton
            default:
                EmptyView()
            }
        }
    }
    
    @ViewBuilder
    private var newRoomButton: some View {
        switch context.viewState.roomListMode {
        case .empty, .rooms:
            Button {
                context.send(viewAction: .startChat)
            } label: {
                CompoundIcon(\.plus)
            }
            //.buttonStyle(.compound(.super, size: .toolbarIcon))
            .accessibilityLabel(L10n.actionStartChat)
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.startChat)
        default:
            EmptyView()
        }
    }
    
    @ViewBuilder
    private var newFeedButton: some View {
        switch context.viewState.postListMode {
        case .empty, .posts:
            Button {
                context.send(viewAction: .newFeed)
            } label: {
                CompoundIcon(\.plus)
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
    
    private var userRewardsToolTip: some View {
        VStack(alignment: .leading) {
            Triangle()
                .fill(.ultraThickMaterial)
                .frame(width: 25, height: 15)
                .padding(.leading, 16)
            
            Button {
                context.send(viewAction: .rewardsIntimated)
            } label: {
                HStack {
                    Text("You earned $\(context.viewState.userRewards.getRefPriceFormatted())")
                        .font(.inter(size: 16))
                    
                    Spacer()
                    
                    Image(systemName: "xmark")
                        .font(.system(size: 16))
                }
                .padding(.all, 16)
                .background(.ultraThickMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }
            .frame(width: 225, height: 30, alignment: .leading)
        }
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
                                   analyticsService: ServiceLocator.shared.analytics,
                                   appSettings: ServiceLocator.shared.settings,
                                   selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
