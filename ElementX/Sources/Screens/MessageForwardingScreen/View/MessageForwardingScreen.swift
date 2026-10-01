//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import MatrixRustSDKMocks
import SwiftUI

struct MessageForwardingScreen: View {
    @ObservedObject var context: MessageForwardingScreenViewModel.Context
    
    var body: some View {
        Form {
            if context.viewState.showsSuggestions {
                Section {
                    ForEach(context.viewState.suggestedRooms, content: row)
                } header: {
                    Text(L10n.commonSuggestions)
                        .compoundListSectionHeader()
                }
            }
            
            Section {
                ForEach(context.viewState.rooms, content: row)
                // Replace these with ScrollView's `scrollPosition` when dropping iOS 16.
            } header: {
                Text(L10n.commonChats)
                    .compoundListSectionHeader()
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
        .compoundList()
        .navigationTitle(L10n.commonForwardTo)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
            ToolbarItem(placement: .confirmationAction) {
                Button(L10n.actionSend) {
                    context.send(viewAction: .send)
                }
                .disabled(context.viewState.selectedRoomIDs.isEmpty)
            }
        }
        .searchController(query: $context.searchQuery, showsCancelButton: false)
        .compoundSearchField()
        .disableAutocorrection(true)
    }
    
    private func row(for room: MessageForwardingRoom) -> some View {
        let isSelected = context.viewState.selectedRoomIDs.contains(room.id)
        
        return MessageForwardingListRow(room: room,
                                        isSelected: isSelected,
                                        isDisabled: context.viewState.isAtRoomSelectionLimit && !isSelected,
                                        context: context)
    }
    
    /// The greedy size of Rectangle can create an issue with the navigation bar when the search is highlighted, so is best to use a fixed frame instead of hidden() or EmptyView()
    private var emptyRectangle: some View {
        Rectangle()
            .frame(width: 0, height: 0)
            .accessibilityHidden(true)
    }
}

private struct MessageForwardingListRow: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let room: MessageForwardingRoom
    let isSelected: Bool
    let isDisabled: Bool
    let context: MessageForwardingScreenViewModel.Context
    
    var body: some View {
        ListRow(label: .avatar(title: room.title,
                               description: room.description,
                               icon: avatar),
                kind: .selection(isSelected: isSelected) {
                    context.send(viewAction: .selectRoom(roomID: room.id))
                })
                .disabled(isDisabled)
    }
    
    @ViewBuilder
    var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            RoomAvatarImage(avatar: room.avatar,
                            avatarSize: .room(on: .messageForwarding),
                            mediaProvider: context.mediaProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

struct MessageForwardingScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let searchingViewModel = makeViewModel(searchQuery: "Foundation")
    
    static var previews: some View {
        ElementNavigationStack {
            MessageForwardingScreen(context: viewModel.context)
        }
        .previewDisplayName("Suggestions")
        .snapshotPreferences(expect: viewModel.context.$viewState.map(\.showsSuggestions))
        
        ElementNavigationStack {
            MessageForwardingScreen(context: searchingViewModel.context)
        }
        .previewDisplayName("Searching")
        .snapshotPreferences(expect: searchingViewModel.context.$viewState.map { !$0.suggestedRooms.isEmpty && !$0.showsSuggestions },
                             precision: 0.999) // The search field's clear button renders inconsistently in snapshots.
    }
    
    static func makeViewModel(searchQuery: String? = nil) -> MessageForwardingScreenViewModel {
        let clientProxy = ClientProxyMock(.init())
        clientProxy.recentlyVisitedRoomIDsReturnValue = .success(["2", "5", "3"])
        clientProxy.roomSummaryForIdentifierClosure = { roomID in [RoomSummary].mockRooms.first { $0.id == roomID } }
        
        let viewModel = MessageForwardingScreenViewModel(forwardingPayload: .init(ids: [.randomEvent],
                                                                                  roomID: "",
                                                                                  contents: [RoomMessageEventContentWithoutRelationSDKMock()]),
                                                         userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                                         roomSummaryProvider: RoomSummaryProviderMock(.init(state: .loaded(.mockRooms))),
                                                         userIndicatorController: UserIndicatorControllerMock())
        
        if let searchQuery {
            viewModel.context.searchQuery = searchQuery
        }
        
        return viewModel
    }
}
