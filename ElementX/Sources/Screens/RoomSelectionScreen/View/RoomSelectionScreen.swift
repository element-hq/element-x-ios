//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomSelectionScreen: View {
    @ObservedObject var context: RoomSelectionScreenViewModel.Context
    
    var body: some View {
        content
            .compoundList()
            .navigationTitle(L10n.screenRoomlistMainSpaceTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .roomSelectionSearch(query: $context.searchQuery)
            .disableAutocorrection(true)
    }
    
    @ViewBuilder
    private var content: some View {
        if context.viewState.showsNoResults {
            noResults
        } else {
            roomList
        }
    }
    
    private var roomList: some View {
        Form {
            Section {
                ForEach(context.viewState.rooms) { room in
                    RoomSelectionListRow(room: room,
                                         isSelected: context.viewState.selectedRoomID == room.id,
                                         mediaProvider: context.mediaProvider) {
                        context.send(viewAction: .selectRoom(roomID: room.id))
                    }
                }
                // Replace these with ScrollView's `scrollPosition` when dropping iOS 16.
            } header: {
                sectionHeader
                    .onAppear {
                        context.send(viewAction: .reachedTop)
                    }
            } footer: {
                emptyRectangle
                    .onAppear {
                        context.send(viewAction: .reachedBottom)
                    }
            }
        }
    }
    
    @ViewBuilder
    private var sectionHeader: some View {
        if context.viewState.isSearching {
            Text(L10n.commonResultsFor(context.searchQuery))
                .compoundListSectionHeader()
                .textCase(.none)
        } else {
            emptyRectangle
        }
    }
    
    private var noResults: some View {
        VStack(spacing: 8) {
            Text(L10n.commonNoResults)
                .font(.compound.headingMDBold)
                .foregroundStyle(.compound.textPrimary)
            
            Text(L10n.commonNoResultsFor(context.searchQuery))
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textSecondary)
        }
        .multilineTextAlignment(.center)
        .accessibilityElement(children: .combine)
        .padding(.horizontal, 24)
        .padding(.top, 40)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
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
        }
        
        ToolbarItem(placement: .confirmationAction) {
            ToolbarButton(role: .confirm(title: L10n.actionShare)) {
                context.send(viewAction: .confirm)
            }
            .disabled(context.viewState.selectedRoomID == nil)
        }
    }
}

private struct RoomSelectionListRow: View {
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    
    let room: RoomSelectionRoom
    let isSelected: Bool
    let mediaProvider: MediaProviderProtocol?
    let action: () -> Void
    
    var body: some View {
        ListRow(label: .avatar(title: room.title,
                               description: room.description.isEmpty ? nil : room.description,
                               icon: avatar),
                kind: .multiSelection(isSelected: isSelected, action: action))
            .accessibilityIdentifier(A11yIdentifiers.roomSelectionScreen.roomName(room.title))
    }
    
    @ViewBuilder
    private var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: room.avatar,
                            avatarSize: .room(on: .roomSelection),
                            mediaProvider: mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

private extension View {
    /// Adds the search field, which iOS 26 places at the bottom of the screen on iPhone.
    @ViewBuilder
    func roomSelectionSearch(query: Binding<String>) -> some View {
        if #available(iOS 26, *) {
            searchable(text: query, prompt: L10n.screenRoomSelectSearchPlaceholder)
                .searchPresentationToolbarBehavior(.avoidHidingContent)
                .compoundSearchField()
        } else {
            searchController(query: query, placeholder: L10n.screenRoomSelectSearchPlaceholder, showsCancelButton: false)
                .compoundSearchField()
        }
    }
}

// MARK: - Previews

struct RoomSelectionScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let selectedViewModel = makeViewModel(selectedRoomID: "2")
    static let resultsViewModel = makeViewModel(searchQuery: "Foundation and")
    static let noResultsViewModel = makeViewModel(searchQuery: "Nothing matches this")
    
    static var previews: some View {
        ElementNavigationStack {
            RoomSelectionScreen(context: viewModel.context)
        }
        .previewDisplayName("Rooms")
        
        ElementNavigationStack {
            RoomSelectionScreen(context: selectedViewModel.context)
        }
        .previewDisplayName("Selected")
        
        ElementNavigationStack {
            RoomSelectionScreen(context: resultsViewModel.context)
        }
        .previewDisplayName("Results")
        .snapshotPreferences(expect: resultsViewModel.context.$viewState.map { $0.rooms.count == 2 },
                             precision: 0.999) // The search field's clear button renders inconsistently in snapshots.
        
        ElementNavigationStack {
            RoomSelectionScreen(context: noResultsViewModel.context)
        }
        .previewDisplayName("No results")
        .snapshotPreferences(expect: noResultsViewModel.context.$viewState.map(\.showsNoResults),
                             precision: 0.999)
    }
    
    static func makeViewModel(selectedRoomID: String? = nil, searchQuery: String? = nil) -> RoomSelectionScreenViewModel {
        let viewModel = RoomSelectionScreenViewModel(userSession: UserSessionMock(.init()),
                                                     roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))))
        
        if let selectedRoomID {
            viewModel.context.send(viewAction: .selectRoom(roomID: selectedRoomID))
        }
        
        if let searchQuery {
            viewModel.context.searchQuery = searchQuery
        }
        
        return viewModel
    }
}
