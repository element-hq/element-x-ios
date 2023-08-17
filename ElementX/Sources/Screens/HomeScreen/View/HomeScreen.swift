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
    enum Constants {
        static let slidingWindowBoundsPadding = 5
    }
    
    @ObservedObject var context: HomeScreenViewModel.Context
    
    @State private var scrollViewAdapter = ScrollViewAdapter()
    @State private var lastScrollDirection: ScrollViewAdapter.ScrollDirection = .up
    @State private var isSearching = false
    
    var bottomBarVisibility: Visibility {
        switch context.viewState.roomListMode {
        case .skeletons: return .hidden
        case .empty: return .visible
        case .rooms: return lastScrollDirection == .up ? .automatic : .hidden
        }
    }
    
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
            .introspect(.scrollView, on: .iOS(.v16)) { scrollView in
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
                // Dispatch allows the view to update after changing the query
                DispatchQueue.main.async { updateVisibleRange() }
            }
            .onReceive(scrollViewAdapter.scrollDirection) { direction in
                withAnimation(.elementDefault) { lastScrollDirection = direction }
            }
            .onChange(of: context.viewState.visibleRooms) { _ in
                // Dispatch gives the view a chance to update
                DispatchQueue.main.async { updateVisibleRange() }
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
        .toolbar(bottomBarVisibility, for: .bottomBar)
        .toolbar { toolbar }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .track(screen: .home)
    }
    
    // MARK: - Private
    
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
        
        ToolbarItemGroup(placement: .bottomBar) {
            Spacer()
            newRoomButton
        }
    }
    
    private var newRoomButton: some View {
        Button {
            context.send(viewAction: .startChat)
        } label: {
            Image(systemName: "square.and.pencil")
        }
    }
    
    private func updateVisibleRange() {
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
        
        // Add some extra padding just to be on the safe side
        let lowerBound = max(0, firstIndex - Constants.slidingWindowBoundsPadding)
        let upperBound = min(Int(context.viewState.rooms.count), lastIndex + Constants.slidingWindowBoundsPadding)

        // This will be deduped and throttled on the view model layer
        context.send(viewAction: .updateVisibleItemRange(range: lowerBound..<upperBound, isScrolling: scrollViewAdapter.isScrolling.value))
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
