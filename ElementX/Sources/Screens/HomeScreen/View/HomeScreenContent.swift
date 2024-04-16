//
// Copyright 2024 New Vector Ltd
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

import SwiftUI

struct HomeScreenContent: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ObservedObject var context: HomeScreenViewModel.Context
    let scrollViewAdapter: ScrollViewAdapter
    
    var body: some View {
        switch context.viewState.roomListMode {
        case .migration:
            migrationView
        default:
            roomList
        }
    }
    
    private var roomList: some View {
        GeometryReader { geometry in
            ScrollView {
                switch context.viewState.roomListMode {
                case .skeletons:
                    LazyVStack(spacing: 0) {
                        ForEach(context.viewState.visibleRooms) { room in
                            HomeScreenRoomCell(room: room, context: context, isSelected: false)
                                .redacted(reason: .placeholder)
                                .shimmer() // Putting this directly on the LazyVStack creates an accordion animation on iOS 16.
                        }
                    }
                    .disabled(true)
                case .empty:
                    HomeScreenEmptyStateLayout(minHeight: geometry.size.height) {
                        topSection
                        
                        HomeScreenEmptyStateView(context: context)
                            .layoutPriority(1)
                    }
                case .rooms:
                    LazyVStack(spacing: 0) {
                        Section {
                            if context.viewState.shouldShowEmptyFilterState {
                                RoomListFiltersEmptyStateView(state: context.filtersState)
                                    .frame(height: geometry.size.height)
                            } else {
                                HomeScreenRoomList(context: context)
                            }
                        } header: {
                            topSection
                        }
                    }
                    .isSearching($context.isSearchFieldFocused)
                    .searchable(text: $context.searchQuery)
                    .compoundSearchField()
                    .disableAutocorrection(true)
                case .migration:
                    EmptyView()
                }
            }
            .introspect(.scrollView, on: .supportedVersions) { scrollView in
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
            .background(
                Button("", action: {
                    context.send(viewAction: .globalSearch)
                })
                .keyboardShortcut(KeyEquivalent("k"), modifiers: [.command])
            )
            .scrollDismissesKeyboard(.immediately)
            .scrollDisabled(context.viewState.roomListMode == .skeletons)
            .scrollBounceBehavior(context.viewState.roomListMode == .empty ? .basedOnSize : .automatic)
            .animation(.elementDefault, value: context.viewState.roomListMode)
            .animation(.none, value: context.viewState.visibleRooms)
        }
    }
    
    @ViewBuilder
    private var topSection: some View {
        VStack(spacing: 0) {
            if !context.isSearchFieldFocused {
                RoomListFiltersView(state: $context.filtersState)
            }
            
            if context.viewState.securityBannerMode == .recoveryKeyConfirmation {
                HomeScreenRecoveryKeyConfirmationBanner(context: context)
            }
            
            if context.viewState.hasPendingInvitations, !context.isSearchFieldFocused, !ServiceLocator.shared.settings.roomListInvitesEnabled {
                HomeScreenInvitesButton(title: L10n.actionInvitesList, hasBadge: context.viewState.hasUnreadPendingInvitations) {
                    context.send(viewAction: .selectInvites)
                }
                .accessibilityIdentifier(A11yIdentifiers.homeScreen.invites)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .background(Color.compound.bgCanvasDefault)
    }
    
    @ViewBuilder
    private var migrationView: some View {
        if UIDevice.current.isPhone {
            if verticalSizeClass == .compact {
                migrationViewContent
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                WaitingDialog {
                    migrationViewContent
                } bottomContent: {
                    EmptyView()
                }
            }
        } else {
            migrationViewContent
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }
    
    private var migrationViewContent: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.compound.iconPrimary)
                .padding(.bottom, 4)
            
            Text(L10n.screenMigrationTitle.tinting(".", color: Asset.Colors.brandColor.swiftUIColor))
                .minimumScaleFactor(0.01)
                .font(.compound.headingXLBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(L10n.screenMigrationMessage)
                .minimumScaleFactor(0.01)
                .font(.compound.bodyLG)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .accessibilityIdentifier(A11yIdentifiers.migrationScreen.message)
        }
        .padding(.horizontal)
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
}
