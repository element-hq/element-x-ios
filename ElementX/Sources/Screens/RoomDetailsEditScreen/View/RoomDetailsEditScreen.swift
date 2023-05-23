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

struct RoomDetailsEditScreen: View {
    @ObservedObject var context: RoomDetailsEditScreenViewModel.Context
    
    var body: some View {
        mainContent
            .scrollDismissesKeyboard(.immediately)
    }
    
    // MARK: - Private
    
    private var mainContent: some View {
        Form {
            avatar
            nameSection
            topicSection
        }
        .navigationTitle("Edit room")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(L10n.actionSave) {
                    context.send(viewAction: .save)
                }
                .disabled(!context.viewState.canSave)
            }
        }
    }
    
    private var avatar: some View {
        LoadableAvatarImage(url: nil,
                            name: "Avatar name",
                            contentID: "some",
                            avatarSize: .user(on: .memberDetails),
                            imageProvider: context.imageProvider)
            .overlay(alignment: .bottomTrailing) {
                if context.viewState.canEditAvatar {
                    avatarOverlayIcon
                }
            }
            .frame(maxWidth: .infinity, alignment: .center)
            .listRowBackground(Color.clear)
    }
    
    private var nameSection: some View {
        Section {
            TextField(L10n.screenCreateRoomRoomNameLabel,
                      text: $context.name,
                      prompt: Text(L10n.screenCreateRoomRoomNamePlaceholder),
                      axis: .horizontal)
                .disabled(!context.viewState.canEditName)
                .background(Color.element.formRowBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } header: {
            Text(L10n.screenCreateRoomRoomNameLabel.uppercased())
                .font(.compound.bodyXS)
                .formSectionHeader()
        }
    }
    
    private var topicSection: some View {
        Section {
            TextField(L10n.screenCreateRoomTopicLabel,
                      text: $context.topic,
                      prompt: Text(L10n.screenCreateRoomTopicPlaceholder),
                      axis: .vertical)
                .disabled(!context.viewState.canEditTopic)
                .lineLimit(3, reservesSpace: true)
        } header: {
            Text(L10n.screenCreateRoomTopicLabel)
                .formSectionHeader()
        }
    }
    
    private var avatarOverlayIcon: some View {
        Image(systemName: "camera")
            .padding(2)
            .imageScale(.small)
            .foregroundColor(.white)
            .background {
                Circle()
                    .foregroundColor(.black)
                    .aspectRatio(1, contentMode: .fill)
            }
    }
}

// MARK: - Previews

struct RoomDetailsEditScreen_Previews: PreviewProvider {
    static let viewModel = RoomDetailsEditScreenViewModel(accountOwner: RoomMemberProxyMock.mockAlice, roomProxy: RoomProxyMock())
    
    static var previews: some View {
        NavigationStack {
            RoomDetailsEditScreen(context: viewModel.context)
        }
    }
}
