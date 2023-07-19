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

import SwiftUI

struct MessageForwardingScreen: View {
    @ObservedObject var context: MessageForwardingScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                ForEach(context.viewState.visibleRooms) { room in
                    MessageForwardingRoomCell(room: room, context: context)
                        .buttonStyle(FormButtonStyle(accessory: .singleSelection(isSelected: context.viewState.selectedRoomID == room.id)))
                }
            }
            .compoundFormSection()
        }
        .compoundForm()
        .navigationTitle(L10n.commonForwardMessage)
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
                .disabled(context.viewState.selectedRoomID == nil)
            }
        }
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .searchableConfiguration(hidesNavigationBar: false)
        .compoundSearchField()
        .disableAutocorrection(true)
    }
}

private struct MessageForwardingRoomCell: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    
    let room: MessageForwardingRoom
    let context: MessageForwardingScreenViewModel.Context
    
    var body: some View {
        Button {
            context.send(viewAction: .selectRoom(roomID: room.id))
        } label: {
            HStack(spacing: 16.0) {
                avatar
                
                VStack(alignment: .leading, spacing: 2.0) {
                    Text(room.name)
                        .font(.compound.bodyMD)
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(1)
                    Text(room.alias ?? room.id)
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .lineLimit(1)
                }
            }
            .accessibilityElement(children: .combine)
        }
    }
    
    @ViewBuilder @MainActor
    var avatar: some View {
        if dynamicTypeSize < .accessibility3 {
            LoadableAvatarImage(url: room.avatarURL,
                                name: room.name,
                                contentID: room.id,
                                avatarSize: .room(on: .messageForwarding),
                                imageProvider: context.imageProvider)
                .dynamicTypeSize(dynamicTypeSize < .accessibility1 ? dynamicTypeSize : .accessibility1)
                .accessibilityHidden(true)
        }
    }
}

// MARK: - Previews

struct MessageForwardingScreen_Previews: PreviewProvider {
    static var previews: some View {
        let summaryProvider = MockRoomSummaryProvider(state: .loaded(.mockRooms))
        let viewModel = MessageForwardingScreenViewModel(roomSummaryProvider: summaryProvider, sourceRoomID: "")
        
        NavigationStack {
            MessageForwardingScreen(context: viewModel.context)
        }
    }
}
