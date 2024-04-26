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

struct RoomDirectorySearchScreen: View {
    @ObservedObject var context: RoomDirectorySearchScreenViewModel.Context
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(context.viewState.rooms) { room in
                        RoomDirectorySearchCell(result: room, imageProvider: context.imageProvider) {
                            context.send(viewAction: .select(roomID: room.id))
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
                        } else {
                            emptyRectangle
                                .onAppear {
                                    context.send(viewAction: .reachedBottom)
                                }
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
                                                 avatarURL: nil,
                                                 canBeJoined: true),
                       RoomDirectorySearchResult(id: "test_2",
                                                 alias: "#test_2:example.com",
                                                 name: "Test 2",
                                                 topic: nil,
                                                 avatarURL: URL.documentsDirectory,
                                                 canBeJoined: false)]
        
        let roomDirectorySearchProxy = RoomDirectorySearchProxyMock(configuration: .init(results: results))
        
        let clientProxy = ClientProxyMock(.init(roomDirectorySearchProxy: roomDirectorySearchProxy))
        
        return RoomDirectorySearchScreenViewModel(clientProxy: clientProxy,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  imageProvider: MockMediaProvider())
    }()
    
    static var previews: some View {
        RoomDirectorySearchScreen(context: viewModel.context)
            .snapshot(delay: 1.0)
    }
}
