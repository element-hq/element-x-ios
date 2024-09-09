//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomDirectorySearchScreen: View {
    @ObservedObject var context: RoomDirectorySearchScreenViewModel.Context
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(context.viewState.rooms) { room in
                        RoomDirectorySearchCell(result: room, mediaProvider: context.mediaProvider) {
                            context.send(viewAction: .select(room: room))
                        }
                    }
                } footer: {
                    VStack(spacing: 0) {
                        if context.viewState.isLoading {
                            ProgressView()
                                .frame(maxWidth: .infinity)
                        } else if context.viewState.rooms.isEmpty {
                            Text(L10n.commonNoResults)
                                .font(.compound.bodyLG)
                                .foregroundColor(.compound.textSecondary)
                                .frame(maxWidth: .infinity)
                                .accessibilityIdentifier(A11yIdentifiers.startChatScreen.searchNoResults)
                        }
                        
                        emptyRectangle
                            .onAppear {
                                context.send(viewAction: .reachedBottom)
                            }
                    }
                    .listRowSeparator(.hidden)
                }
            }
            .listStyle(.plain)
            .environment(\.defaultMinListRowHeight, 48)
            .scrollContentBackground(.hidden)
            .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
            .isSearching($context.isSearching)
            .searchable(text: $context.searchString, placement: .navigationBarDrawer(displayMode: .always))
            .navigationTitle(L10n.screenRoomDirectorySearchTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(L10n.actionCancel) {
                        context.send(viewAction: .dismiss)
                    }
                }
            }
        }
    }
    
    // The greedy size of Rectangle can create an issue with the navigation bar when the search is highlighted, so is best to use a fixed frame instead of hidden() or EmptyView()
    private var emptyRectangle: some View {
        Rectangle()
            .frame(width: 0, height: 0)
    }
}

// MARK: - Previews

struct RoomDirectorySearchScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel: RoomDirectorySearchScreenViewModel = {
        let results = [RoomDirectorySearchResult(id: "test_1",
                                                 alias: "#test_1:example.com",
                                                 name: "Test 1",
                                                 topic: "Test description 1",
                                                 avatar: .room(id: "test_1",
                                                               name: "Test 1",
                                                               avatarURL: nil),
                                                 canBeJoined: true),
                       RoomDirectorySearchResult(id: "test_2",
                                                 alias: "#test_2:example.com",
                                                 name: "Test 2",
                                                 topic: nil,
                                                 avatar: .room(id: "test_2",
                                                               name: "Test 2",
                                                               avatarURL: .documentsDirectory),
                                                 canBeJoined: false)]
        
        let roomDirectorySearchProxy = RoomDirectorySearchProxyMock(configuration: .init(results: results))
        
        let clientProxy = ClientProxyMock(.init(roomDirectorySearchProxy: roomDirectorySearchProxy))
        
        return RoomDirectorySearchScreenViewModel(clientProxy: clientProxy,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  mediaProvider: MockMediaProvider())
    }()
    
    static var previews: some View {
        RoomDirectorySearchScreen(context: viewModel.context)
            .snapshotPreferences(delay: 1.0)
    }
}
