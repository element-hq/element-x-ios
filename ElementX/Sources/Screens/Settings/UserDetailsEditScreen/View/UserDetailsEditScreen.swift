//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct UserDetailsEditScreen: View {
    @ObservedObject var context: UserDetailsEditScreenViewModel.Context
    @FocusState private var focus: Bool
        
    var body: some View {
        Form {
            Section {
                avatar
            } footer: {
                Text(context.viewState.userID)
                    .frame(maxWidth: .infinity)
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textPrimary)
                    .padding(.bottom, 16)
            }
            
            nameSection
        }
        .compoundList()
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(L10n.screenEditProfileTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
    }
    
    // MARK: - Private
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionSave) {
                context.send(viewAction: .save)
                focus = false
            }
            .disabled(!context.viewState.canSave)
        }
    }

    private var avatar: some View {
        Button {
            context.send(viewAction: .presentMediaSource)
        } label: {
            OverridableAvatarImage(overrideURL: context.viewState.localMedia?.thumbnailURL,
                                   url: context.viewState.selectedAvatarURL,
                                   name: context.viewState.currentDisplayName,
                                   contentID: context.viewState.userID,
                                   avatarSize: .user(on: .editUserDetails),
                                   mediaProvider: context.mediaProvider)
                .overlay(alignment: .bottomTrailing) {
                    avatarOverlayIcon
                }
                .confirmationDialog("", isPresented: $context.showMediaSheet) {
                    mediaActionSheet
                }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
    }

    private var nameSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenEditProfileDisplayNamePlaceholder),
                    kind: .textField(text: $context.name, axis: .horizontal))
                .focused($focus)
        } header: {
            Text(L10n.screenEditProfileDisplayName)
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

struct UserDetailsEditScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = UserDetailsEditScreenViewModel(clientProxy: ClientProxyMock(.init(userID: "@stefan:matrix.org")),
                                                          mediaProvider: MockMediaProvider(),
                                                          userIndicatorController: UserIndicatorControllerMock.default)
    
    static var previews: some View {
        NavigationStack {
            UserDetailsEditScreen(context: viewModel.context)
        }
    }
}
