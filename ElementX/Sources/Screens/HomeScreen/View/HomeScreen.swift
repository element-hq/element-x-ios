//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SentrySwiftUI
import SwiftUI

struct HomeScreen: View {
    @ObservedObject var context: HomeScreenViewModel.Context
    
    @State private var scrollViewAdapter = ScrollViewAdapter()
    
    @Namespace private var navigationTransitionNamespace
    private enum NavigationTransitionSourceID {
        case spaceFilters
    }
    
    var body: some View {
        HomeScreenContent(context: context, scrollViewAdapter: scrollViewAdapter)
            .alert(item: $context.alertInfo)
            .alert(item: $context.leaveRoomAlertItem,
                   actions: leaveRoomAlertActions,
                   message: leaveRoomAlertMessage)
            .navigationTitle(title)
            .toolbar { toolbar }
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .track(screen: .Home)
            .toolbarBloom(hasSearchBar: true)
            .sentryTrace("\(Self.self)")
            .sheet(item: $context.spaceFiltersViewModel) { vm in
                ChatsSpaceFiltersScreen(context: vm.context)
                    .navigationTransition(.zoom(sourceID: NavigationTransitionSourceID.spaceFilters,
                                                in: navigationTransitionNamespace))
            }
    }
    
    // MARK: - Private
    
    private var title: String {
        if let selectedSpace = context.viewState.selectedSpaceFilter {
            selectedSpace.room.name
        } else {
            L10n.screenRoomlistMainSpaceTitle
        }
    }
        
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            settingsButton
                .buttonStyle(.borderless)
        }
        
        ToolbarItem(placement: .primaryAction) {
            if #available(iOS 26, *) {
                newRoomButton
            } else {
                newRoomButton
                    .buttonStyle(.compound(.super, size: .toolbarIcon))
            }
        }
        
        if context.viewState.spaceFiltersEnabled, context.viewState.shouldShowSpaceFilters {
            if #available(iOS 26, *) {
                ToolbarSpacer(.fixed, placement: .primaryAction)
            }
               
            ToolbarItem(placement: .primaryAction) {
                SpaceFiltersButton(selected: context.viewState.selectedSpaceFilter != nil) {
                    context.send(viewAction: .spaceFilters)
                }
                .matchedTransitionSource(id: NavigationTransitionSourceID.spaceFilters,
                                         in: navigationTransitionNamespace)
            }
        }
    }
    
    private var settingsButton: some View {
        Button {
            context.send(viewAction: .showSettings)
        } label: {
            LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                name: context.viewState.userDisplayName,
                                contentID: context.viewState.userID,
                                avatarSize: .user(on: .chats),
                                mediaProvider: context.mediaProvider)
                .accessibilityIdentifier(A11yIdentifiers.homeScreen.userAvatar)
                .clipShape(.circle)
                .overlayBadge(10, isBadged: context.viewState.requiresExtraAccountSetup)
                .compositingGroup()
        }
        .accessibilityLabel(L10n.commonSettings)
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
    
    private struct SpaceFiltersButton: View {
        var selected = false
        var action: () -> Void
        
        var body: some View {
            if #available(iOS 26, *) {
                if selected {
                    content
                        .backportButtonStyleGlassProminent()
                        .tint(.compound.bgActionPrimaryRest)
                } else {
                    content
                }
            } else {
                if selected {
                    content
                        .buttonStyle(.compound(.primary, size: .toolbarIcon))
                } else {
                    content
                        .buttonStyle(.compound(.tertiary, size: .toolbarIcon))
                }
            }
        }
        
        private var content: some View {
            Button {
                action()
            } label: {
                CompoundIcon(\.filter)
            }
            .accessibilityLabel(L10n.screenRoomlistYourSpaces)
            .accessibilityAddTraits(selected ? .isSelected : [])
            .accessibilityIdentifier(A11yIdentifiers.homeScreen.spaceFilters)
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
