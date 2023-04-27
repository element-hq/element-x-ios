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

import Compound
import SwiftUI

struct HomeScreen: View {
    enum Constants {
        static let slidingWindowBoundsPadding = 5
    }
    
    @ObservedObject var context: HomeScreenViewModel.Context
    
    @State private var scrollViewAdapter = ScrollViewAdapter()
    @State private var showingLogoutConfirmation = false
    
    var body: some View {
        ScrollView {
            if context.viewState.showSessionVerificationBanner {
                sessionVerificationBanner
            }

            if context.viewState.hasPendingInvitations, ServiceLocator.shared.settings.invitesFlowEnabled {
                HomeScreenInvitesButton(title: L10n.actionInvitesList, hasBadge: context.viewState.hasUnreadPendingInvitations) {
                    context.send(viewAction: .selectInvites)
                }
                .padding(.trailing, 16)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            
            if context.viewState.roomListMode == .skeletons {
                LazyVStack(spacing: 0) {
                    ForEach(context.viewState.visibleRooms) { room in
                        HomeScreenRoomCell(room: room, context: context)
                            .redacted(reason: .placeholder)
                    }
                }
                .shimmer()
                .disabled(true)
            } else {
                LazyVStack(spacing: 0) {
                    ForEach(context.viewState.visibleRooms) { room in
                        Group {
                            if room.isPlaceholder {
                                HomeScreenRoomCell(room: room, context: context)
                                    .redacted(reason: .placeholder)
                            } else {
                                HomeScreenRoomCell(room: room, context: context)
                                    .contextMenu {
                                        roomContextualMenu
                                    }
                            }
                        }
                    }
                }
                .searchable(text: $context.searchQuery)
                .compoundSearchField()
                .disableAutocorrection(true)
            }
        }
        .introspectScrollView { scrollView in
            guard scrollView != scrollViewAdapter.scrollView else { return }
            scrollViewAdapter.scrollView = scrollView
        }
        .onReceive(scrollViewAdapter.didScroll) { _ in
            updateVisibleRange()
        }
        .onReceive(scrollViewAdapter.isScrolling) { _ in
            updateVisibleRange()
        }
        .onChange(of: context.searchQuery) { searchQuery in
            if searchQuery.isEmpty {
                // Allow the view to update after changing the query
                DispatchQueue.main.async {
                    updateVisibleRange()
                }
            }
        }
        .onChange(of: context.viewState.visibleRooms) { _ in
            // Give the view a chance to update
            DispatchQueue.main.async {
                updateVisibleRange()
            }
        }
        .scrollDismissesKeyboard(.immediately)
        .scrollDisabled(context.viewState.roomListMode == .skeletons)
        .animation(.elementDefault, value: context.viewState.showSessionVerificationBanner)
        .animation(.elementDefault, value: context.viewState.roomListMode)
        .alert(item: $context.alertInfo) { $0.alert }
        .navigationTitle(L10n.screenRoomlistMainSpaceTitle)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                userMenuButton
            }
            if context.viewState.startChatFlowEnabled {
                ToolbarItemGroup(placement: .bottomBar) {
                    Spacer()
                    newRoomButton
                }
            }
        }
        .background(Color.element.background.ignoresSafeArea())
        .track(screen: .home)
    }

    @ViewBuilder
    private var userMenuButton: some View {
        Menu {
            Section {
                Button(action: settings) {
                    Label(L10n.commonSettings, systemImage: "gearshape")
                }
            }
            Section {
                if let permalink = context.viewState.invitePermalink {
                    ShareLink(item: permalink) {
                        Label(L10n.actionInvite, systemImage: "square.and.arrow.up")
                    }
                }
                Button(action: feedback) {
                    Label(L10n.commonReportABug, systemImage: "questionmark.circle")
                }
            }
            Section {
                Button(role: .destructive) {
                    showingLogoutConfirmation = true
                } label: {
                    Label(L10n.screenSignoutPreferenceItem, systemImage: "rectangle.portrait.and.arrow.right")
                }
            }
        } label: {
            LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                name: context.viewState.userDisplayName,
                                contentID: context.viewState.userID,
                                avatarSize: .user(on: .home),
                                imageProvider: context.imageProvider)
                .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
        }
        .alert(L10n.screenSignoutConfirmationDialogTitle,
               isPresented: $showingLogoutConfirmation) {
            Button(L10n.screenSignoutConfirmationDialogSubmit,
                   role: .destructive,
                   action: signOut)
        } message: {
            Text(L10n.screenSignoutConfirmationDialogContent)
        }
        .accessibilityLabel(L10n.a11yUserMenu)
    }
    
    @ViewBuilder
    private var roomContextualMenu: some View {
        Button(action: settings) {
            Label(L10n.commonSettings, systemImage: "gearshape")
        }
        Button(role: .destructive, action: settings) {
            Label(L10n.actionLeaveRoom, systemImage: "rectangle.portrait.and.arrow.right")
        }
    }
    
    private var newRoomButton: some View {
        Button(action: startChat) {
            Image(systemName: "square.and.pencil")
        }
    }
    
    private var sessionVerificationBanner: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 16) {
                    Text(L10n.sessionVerificationBannerTitle)
                        .font(.compound.bodyLGSemibold)
                        .foregroundColor(.element.systemPrimaryLabel)
                    
                    Spacer()
                    
                    Button {
                        context.send(viewAction: .skipSessionVerification)
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(.element.secondaryContent)
                            .frame(width: 12, height: 12)
                    }
                }
                Text(L10n.sessionVerificationBannerMessage)
                    .font(.compound.bodyMD)
                    .foregroundColor(.element.secondaryContent)
            }
            
            Button(L10n.actionContinue) {
                context.send(viewAction: .verifySession)
            }
            .frame(maxWidth: .infinity)
            .buttonStyle(.elementCapsuleProminent)
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.verificationBannerContinue)
        }
        .padding(16)
        .background(Color.element.system)
        .cornerRadius(14)
        .padding(.horizontal, 16)
    }

    private func settings() {
        context.send(viewAction: .userMenu(action: .settings))
    }

    private func startChat() {
        context.send(viewAction: .startChat)
    }
    
    private func feedback() {
        context.send(viewAction: .userMenu(action: .feedback))
    }

    private func signOut() {
        context.send(viewAction: .userMenu(action: .signOut))
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
}

// MARK: - Previews

struct HomeScreen_Previews: PreviewProvider {
    static var previews: some View {
        body(.loading)
        body(.loaded(.mockRooms))
    }
    
    static func body(_ state: MockRoomSummaryProviderState) -> some View {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "John Doe",
                                                                       roomSummaryProvider: MockRoomSummaryProvider(state: state)),
                                          mediaProvider: MockMediaProvider())
        
        let viewModel = HomeScreenViewModel(userSession: userSession,
                                            attributedStringBuilder: AttributedStringBuilder())
        
        return NavigationStack {
            HomeScreen(context: viewModel.context)
        }
    }
}
