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
            .scrollContentBackground(.hidden)
            .background(Color.element.formBackground.ignoresSafeArea())
            .scrollDismissesKeyboard(.immediately)
    }
    
    // MARK: - Private
    
    #warning("Localize me")
    private var mainContent: some View {
        Form {
            avatar
            nameSection
            topicSection
        }
        .navigationTitle("Edit room")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
            
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
            let canEditName = context.viewState.canEditName
            
            TextField(L10n.screenCreateRoomRoomNameLabel,
                      text: $context.name,
                      prompt: canEditName ? Text(L10n.screenCreateRoomRoomNamePlaceholder) : nil,
                      axis: .horizontal)
                .disabled(!canEditName)
                .listRowBackground(canEditName ? nil : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } header: {
            Text(L10n.screenCreateRoomRoomNameLabel.uppercased())
                .font(.compound.bodyXS)
                .formSectionHeader()
        }
        .formSectionStyle()
    }
    
    private var topicSection: some View {
        Section {
            let canEditTopic = context.viewState.canEditTopic
            
            TextField(L10n.screenCreateRoomTopicLabel,
                      text: $context.topic,
                      prompt: canEditTopic ? Text(L10n.screenCreateRoomTopicPlaceholder) : nil,
                      axis: .vertical)
                .disabled(!canEditTopic)
                .listRowBackground(canEditTopic ? nil : Color.clear)
                .lineLimit(3, reservesSpace: true)
        } header: {
            Text(L10n.screenCreateRoomTopicLabel)
                .formSectionHeader()
        }
        .formSectionStyle()
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
    static let viewModel = RoomDetailsEditScreenViewModel(accountOwner: RoomMemberProxyMock.mockAlice, roomProxy: RoomProxyMock(), userIndicatorController: MockUserIndicatorController())
    
    static var previews: some View {
        NavigationStack {
            RoomDetailsEditScreen(context: viewModel.context)
        }
    }
}
