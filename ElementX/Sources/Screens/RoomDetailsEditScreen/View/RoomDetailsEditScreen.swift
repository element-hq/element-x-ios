//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomDetailsEditScreen: View {
    @ObservedObject var context: RoomDetailsEditScreenViewModel.Context
    
    private enum Focus { case name, topic }
    @FocusState private var focus: Focus?
    
    private var isSpace: Bool {
        context.viewState.isSpace
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
        .alert(item: $context.alertInfo)
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
                                   shape: isSpace ? .roundedRect : .circle,
                                   avatarSize: .room(on: isSpace ? .editSpaceDetails : .editRoomDetails),
                                   mediaProvider: context.mediaProvider)
                .accessibilityLabel(L10n.a11yEditAvatar)
                .confirmationDialog("", isPresented: $context.showMediaSheet) {
                    mediaActionSheet
                }
        }
        .buttonStyle(EditAvatarButtonStyle())
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
            Text(L10n.commonName)
                .compoundListSectionHeader()
        }
    }
    
    private var topicSection: some View {
        Section {
            if context.viewState.canEditTopic {
                ListRow(label: .plain(title: isSpace ? L10n.commonSpaceTopicPlaceholder : L10n.commonTopicPlaceholder),
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
        
        Button {
            context.send(viewAction: .displayFilePicker)
        } label: {
            Text(L10n.actionChooseFile)
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
    static let editableViewModel = makeViewModel(readOnly: false)
    static let readOnlyViewModel = makeViewModel(readOnly: true)
    static let editableSpaceViewModel = makeViewModel(readOnly: false, isSpace: true)
    
    static var previews: some View {
        ElementNavigationStack {
            RoomDetailsEditScreen(context: readOnlyViewModel.context)
        }
        .previewDisplayName("Read only")
        
        ElementNavigationStack {
            RoomDetailsEditScreen(context: editableViewModel.context)
        }
        .snapshotPreferences(expect: editableViewModel.context.$viewState.map { $0.canEditTopic == true })
        .previewDisplayName("Editable")
        
        ElementNavigationStack {
            RoomDetailsEditScreen(context: editableSpaceViewModel.context)
        }
        .snapshotPreferences(expect: editableSpaceViewModel.context.$viewState.map { $0.canEditTopic == true })
        .previewDisplayName("Space")
    }
    
    static func makeViewModel(readOnly: Bool, isSpace: Bool = false) -> RoomDetailsEditScreenViewModel {
        let members: [RoomMemberProxyMock] = readOnly ? [.mockAlice] : [.mockMeAdmin]
        let roomProxy = JoinedRoomProxyMock(.init(id: "test_id",
                                                  name: isSpace ? "Space" : "Room",
                                                  isSpace: isSpace,
                                                  members: members))
        
        return RoomDetailsEditScreenViewModel(roomProxy: roomProxy,
                                              userSession: UserSessionMock(.init()),
                                              mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: ServiceLocator.shared.settings),
                                              userIndicatorController: UserIndicatorControllerMock.default)
    }
}
