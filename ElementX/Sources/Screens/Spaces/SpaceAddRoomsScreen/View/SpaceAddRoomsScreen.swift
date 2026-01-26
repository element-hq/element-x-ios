//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SpaceAddRoomsScreen: View {
    @Bindable var context: SpaceAddRoomsScreenViewModel.Context
    
    @State private var formWidth = CGFloat.zero
    
    var showTopSection: Bool {
        !context.viewState.selectedRooms.isEmpty
    }
    
    var body: some View {
        Form {
            Section {
                EmptyView()
            } header: {
                VStack(alignment: .leading, spacing: 24) {
                    Text(L10n.screenSpaceAddRoomsRoomAccessDescription)
                        .font(.compound.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal, 16)
                    
                    if showTopSection {
                        selectedRoomsSection
                            .textCase(.none)
                            .frame(width: formWidth)
                            .padding(.bottom, -8)
                    }
                }
                .listRowInsets(EdgeInsets())
            }
            
            if !context.viewState.roomsSection.rooms.isEmpty {
                roomsSection
            }
        }
        .compoundList()
        .navigationTitle(L10n.actionAddExistingRooms)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .searchController(query: $context.searchQuery, showsCancelButton: false)
        .compoundSearchField()
        .disableAutocorrection(true)
        .onChange(of: context.searchQuery) { context.send(viewAction: .searchQueryChanged) }
        .readWidth($formWidth)
    }
    
    @ScaledMetric private var selectedRoomCellWidth: CGFloat = 80
    
    private var selectedRoomsSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(context.viewState.selectedRooms, id: \.id) { room in
                    SpaceAddRoomsScreenSelectedItem(room: room, mediaProvider: context.mediaProvider) {
                        context.send(viewAction: .toggleRoom(room))
                    }
                    .frame(width: selectedRoomCellWidth)
                }
            }
            .padding(.horizontal, 16)
            .scrollTargetLayout()
        }
        .scrollPosition(id: $context.selectedRoomsPosition, anchor: .trailing)
    }
    
    private var roomsSection: some View {
        Section {
            ForEach(context.viewState.roomsSection.rooms) { room in
                SpaceAddRoomsListRow(room: room,
                                     isSelected: context.viewState.selectedRooms.contains { $0.id == room.id },
                                     context: context)
            }
            // Replace these with ScrollView's `scrollPosition` when dropping iOS 16.
        } header: {
            switch context.viewState.roomsSection.type {
            case .searchResults:
                emptyRectangle
                    .onAppear {
                        context.send(viewAction: .reachedTop)
                    }
            case .suggestions:
                if let sectionTitle = context.viewState.roomsSection.title {
                    Text(sectionTitle)
                }
            }
        } footer: {
            if context.viewState.roomsSection.type == .searchResults {
                emptyRectangle
                    .onAppear {
                        context.send(viewAction: .reachedBottom)
                    }
            }
        }
    }
    
    /// The greedy size of Rectangle can create an issue with the navigation bar when the search is highlighted, so is best to use a fixed frame instead of hidden() or EmptyView()
    private var emptyRectangle: some View {
        Rectangle()
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            ToolbarButton(role: .cancel) {
                context.send(viewAction: .cancel)
            }
            .accessibilityIdentifier(A11yIdentifiers.spaceAddRoomsScreen.cancel)
        }
        
        ToolbarItem(placement: .confirmationAction) {
            ToolbarButton(role: .save) {
                context.send(viewAction: .save)
            }
            .disabled(context.viewState.selectedRooms.isEmpty)
        }
    }
}

private struct SpaceAddRoomsListRow: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let room: SpaceAddRoomsScreenRoom
    let isSelected: Bool
    let context: SpaceAddRoomsScreenViewModel.Context
    
    var body: some View {
        ListRow(label: .avatar(title: room.title,
                               description: room.description,
                               icon: avatar),
                kind: .multiSelection(isSelected: isSelected) {
                    context.send(viewAction: .toggleRoom(room))
                })
    }
    
    @ViewBuilder @MainActor
    var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: room.avatar,
                            avatarSize: .room(on: .spaceAddRooms),
                            mediaProvider: context.mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

struct SpaceAddRoomsScreen_Previews: PreviewProvider, TestablePreview {
    static let summaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
    static let viewModel = makeViewModel()
    static let searchingViewModel = makeViewModel(searchQuery: "Foundation")
    static let selectedViewModel = makeViewModel(searchQuery: "Foundation", hasSelection: true)
    
    static var previews: some View {
        NavigationStack {
            SpaceAddRoomsScreen(context: viewModel.context)
        }
        .previewDisplayName("Suggested")
        .snapshotPreferences(expect: viewModel.context.observe(\.viewState.roomsSection).map {
            $0.type == .suggestions && !$0.rooms.isEmpty
        })
        
        NavigationStack {
            SpaceAddRoomsScreen(context: searchingViewModel.context)
        }
        .previewDisplayName("Searching")
        
        NavigationStack {
            SpaceAddRoomsScreen(context: selectedViewModel.context)
        }
        .previewDisplayName("Selected")
    }
    
    static func makeViewModel(searchQuery: String? = nil, hasSelection: Bool = false) -> SpaceAddRoomsScreenViewModel {
        let spaceRoomListProxy = SpaceRoomListProxyMock(.init(spaceServiceRoom: SpaceServiceRoom.mock(isSpace: true)))
        
        let clientProxy = ClientProxyMock(.init())
        clientProxy.recentlyVisitedRoomsFilterReturnValue = .mockRooms
        
        let viewModel = SpaceAddRoomsScreenViewModel(spaceRoomListProxy: spaceRoomListProxy,
                                                     userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                     roomSummaryProvider: summaryProvider,
                                                     userIndicatorController: UserIndicatorControllerMock())
        
        if let searchQuery {
            viewModel.context.searchQuery = searchQuery
            viewModel.context.send(viewAction: .searchQueryChanged)
        }
        
        if hasSelection {
            viewModel.state.selectedRooms = Array(summaryProvider.roomListPublisher.value.prefix(2)).map(SpaceAddRoomsScreenRoom.init)
        }
        
        return viewModel
    }
}
