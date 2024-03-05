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
        .compoundList()
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(L10n.screenRoomDetailsEditRoomTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .track(screen: .RoomSettings)
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
            if context.viewState.canEditName {
                ListRow(label: .plain(title: L10n.commonRoomNamePlaceholder),
                        kind: .textField(text: $context.name, axis: .horizontal))
                    .focused($focus, equals: .name)
            } else {
                ListRow(kind: .custom {
                    ListRowLabel.plain(title: context.viewState.nameRowTitle)
                        .listRowBackground(Color.clear)
                })
            }
        } header: {
            Text(L10n.commonRoomName)
                .compoundListSectionHeader()
        }
    }
    
    private var topicSection: some View {
        Section {
            if context.viewState.canEditTopic {
                ListRow(label: .plain(title: L10n.commonTopicPlaceholder),
                        kind: .textField(text: $context.topic, axis: .vertical))
                    .focused($focus, equals: .topic)
                    .lineLimit(3...)
            } else {
                ListRow(kind: .custom {
                    ListRowLabel.plain(title: context.viewState.topicRowTitle)
                        .listRowBackground(Color.clear)
                })
            }
        } header: {
            Text(L10n.commonTopic)
                .compoundListSectionHeader()
        }
    }
    
    private var avatarOverlayIcon: some View {
        CompoundIcon(\.editSolid, size: .xSmall, relativeTo: .compound.bodyLG)
            .foregroundColor(.white)
            .padding(4)
            .background {
                Circle()
                    .foregroundColor(.black)
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

struct RoomDetailsEditScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomDetailsEditScreenViewModel(roomProxy: RoomProxyMock(with: .init(id: "test_id",
                                                                                               name: "Room",
                                                                                               members: [.mockMeAdmin])),
                                                          mediaProvider: MockMediaProvider(),
                                                          userIndicatorController: UserIndicatorControllerMock.default)
    
    static let readOnlyViewModel = {
        let accountOwner = RoomMemberProxyMock.mockMe
        return RoomDetailsEditScreenViewModel(roomProxy: RoomProxyMock(with: .init(id: "test_id",
                                                                                   name: "Room",
                                                                                   members: [.mockMe])),
                                              mediaProvider: MockMediaProvider(),
                                              userIndicatorController: UserIndicatorControllerMock.default)
    }()
    
    static var previews: some View {
        NavigationStack {
            RoomDetailsEditScreen(context: viewModel.context)
        }
        .previewDisplayName("Normal")
        .snapshot(delay: 0.1)
        
        NavigationStack {
            RoomDetailsEditScreen(context: readOnlyViewModel.context)
        }
        .previewDisplayName("Read only")
        .snapshot(delay: 0.1)
    }
}
