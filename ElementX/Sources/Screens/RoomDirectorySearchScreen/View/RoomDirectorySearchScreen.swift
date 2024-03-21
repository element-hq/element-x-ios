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
                    ForEach(context.viewState.searchResults) {
                        RoomDirectorySearchCell(result: $0, imageProvider: context.imageProvider)
                    }
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
}

// MARK: - Previews

struct RoomDirectorySearchScreenScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomDirectorySearchScreenViewModel(roomDirectorySearch: RoomDirectorySearchProxyMock(configuration: .init(results: [.init(id: "test_1",
                                                                                                                                                     alias: "#test_1:example.com",
                                                                                                                                                     name: "Test 1",
                                                                                                                                                     topic: "Test description 1",
                                                                                                                                                     avatarURL: nil,
                                                                                                                                                     canBeJoined: true),
        .init(id: "test_2",
              alias: "#test_2:example.com",
              name: "Test 2",
              topic: "Test description 2",
              avatarURL: URL.documentsDirectory,
              canBeJoined: false)])),
    userIndicatorController: UserIndicatorControllerMock(),
    imageProvider: MockMediaProvider())
    
    static var previews: some View {
        RoomDirectorySearchScreen(context: viewModel.context)
            .snapshot(delay: 1.0)
    }
}
