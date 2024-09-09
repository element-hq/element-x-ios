//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
                                   mediaProvider: context.mediaProvider)
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
    static let editableViewModel = {
        let roomProxy = JoinedRoomProxyMock(.init(id: "test_id",
                                                  name: "Room",
                                                  members: [.mockMeAdmin]))
        
        return RoomDetailsEditScreenViewModel(roomProxy: roomProxy,
                                              mediaProvider: MockMediaProvider(),
                                              userIndicatorController: UserIndicatorControllerMock.default)
    }()
    
    static let readOnlyViewModel = {
        let roomProxy = JoinedRoomProxyMock(.init(id: "test_id",
                                                  name: "Room",
                                                  members: [.mockAlice]))
        
        return RoomDetailsEditScreenViewModel(roomProxy: roomProxy,
                                              mediaProvider: MockMediaProvider(),
                                              userIndicatorController: UserIndicatorControllerMock.default)
    }()
    
    static var previews: some View {
        NavigationStack {
            RoomDetailsEditScreen(context: readOnlyViewModel.context)
        }
        .previewDisplayName("Read only")
        .snapshotPreferences(delay: 0.25)
        
        NavigationStack {
            RoomDetailsEditScreen(context: editableViewModel.context)
        }
        .previewDisplayName("Editable")
        .snapshotPreferences(delay: 0.25)
    }
}
