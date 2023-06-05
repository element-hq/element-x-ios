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
    @FocusState private var focus: Focus?
    
    private enum Focus {
        case name
        case topic
    }
    
    var body: some View {
        Form {
            avatar
            nameSection
            topicSection
        }
        .elementFormStyle()
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(L10n.screenRoomDetailsEditRoomTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
    }
    
    // MARK: - Private
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionSave) {
                context.send(viewAction: .save)
                focus = nil
            }
            .disabled(!context.viewState.canSave)
        }
    }

    private var avatar: some View {
        Button {
            context.send(viewAction: .presentMediaSource)
        } label: {
            OverridableAvatarImage(overrideURL: context.viewState.localMedia?.thumbnailURL,
                                   url: context.viewState.avatarURL,
                                   name: context.viewState.initialName,
                                   contentID: context.viewState.roomID,
                                   avatarSize: .user(on: .memberDetails),
                                   imageProvider: context.imageProvider)
                .overlay(alignment: .bottomTrailing) {
                    if context.viewState.canEditAvatar {
                        avatarOverlayIcon
                    }
                }
                .confirmationDialog("", isPresented: $context.showMediaSheet) {
                    mediaActionSheet
                }
        }
        .buttonStyle(.plain)
        .disabled(!context.viewState.canEditAvatar)
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
    }

    private var nameSection: some View {
        Section {
            let canEditName = context.viewState.canEditName
            
            TextField(L10n.commonRoomName,
                      text: $context.name,
                      prompt: canEditName ? Text(L10n.commonRoomNamePlaceholder) : nil,
                      axis: .horizontal)
                .focused($focus, equals: .name)
                .font(.compound.bodyLG)
                .foregroundColor(.element.primaryContent)
                .disabled(!canEditName)
                .listRowBackground(canEditName ? nil : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 8))
        } header: {
            Text(L10n.commonRoomName)
                .formSectionHeader()
        }
        .formSectionStyle()
    }
    
    private var topicSection: some View {
        Section {
            let canEditTopic = context.viewState.canEditTopic
            
            TextField(L10n.commonTopic,
                      text: $context.topic,
                      prompt: canEditTopic ? Text(L10n.commonTopicPlaceholder) : nil,
                      axis: .vertical)
                .focused($focus, equals: .topic)
                .font(.compound.bodyLG)
                .foregroundColor(.element.primaryContent)
                .disabled(!canEditTopic)
                .listRowBackground(canEditTopic ? nil : Color.clear)
                .lineLimit(3, reservesSpace: true)
        } header: {
            Text(L10n.commonTopic)
                .formSectionHeader()
        }
        .formSectionStyle()
    }
    
    private var avatarOverlayIcon: some View {
        Image(systemName: "camera")
            .font(.system(size: 14, weight: .semibold))
            .padding(3)
            .imageScale(.small)
            .foregroundColor(.white)
            .background {
                Circle()
                    .foregroundColor(.black)
                    .aspectRatio(1, contentMode: .fill)
            }
    }
    
    @ViewBuilder
    private var mediaActionSheet: some View {
        Button {
            context.send(viewAction: .displayCameraPicker)
        } label: {
            Text(L10n.actionTakePhoto)
        }
        Button {
            context.send(viewAction: .displayMediaPicker)
        } label: {
            Text(L10n.actionChoosePhoto)
        }
        if context.viewState.showDeleteImageAction {
            Button(role: .destructive) {
                context.send(viewAction: .removeImage)
            } label: {
                Text(L10n.actionRemove)
            }
        }
    }
}

// MARK: - Previews

struct RoomDetailsEditScreen_Previews: PreviewProvider {
    static let viewModel = RoomDetailsEditScreenViewModel(accountOwner: RoomMemberProxyMock.mockAlice,
                                                          mediaProvider: MockMediaProvider(),
                                                          roomProxy: RoomProxyMock(with: .init(name: "Room", displayName: "Room")),
                                                          userIndicatorController: MockUserIndicatorController())
    
    static var previews: some View {
        NavigationStack {
            RoomDetailsEditScreen(context: viewModel.context)
        }
    }
}
