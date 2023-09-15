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

struct UserDetailsEditScreen: View {
    @ObservedObject var context: UserDetailsEditScreenViewModel.Context
    @FocusState private var focus: Focus?
    
    private enum Focus {
        case name
        case topic
    }
    
    var body: some View {
        Form {
            avatar
            nameSection
        }
        .compoundList()
        .scrollDismissesKeyboard(.immediately)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .track(screen: .roomSettings)
    }
    
    // MARK: - Private
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
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
                                   url: context.viewState.replaceableAvatarURL,
                                   name: context.viewState.currentDisplayName,
                                   contentID: context.viewState.userID,
                                   avatarSize: .user(on: .memberDetails),
                                   imageProvider: context.imageProvider)
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
                .focused($focus, equals: .name)
        } header: {
            Text(L10n.screenEditProfileDisplayName)
                .compoundListSectionHeader()
        }
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

struct UserDetailsEditScreen_Previews: PreviewProvider {
    static let viewModel = UserDetailsEditScreenViewModel(clientProxy: MockClientProxy(userID: "@stefan:matrix.org"),
                                                          mediaProvider: MockMediaProvider(),
                                                          userIndicatorController: UserIndicatorControllerMock.default)
    
    static var previews: some View {
        NavigationStack {
            UserDetailsEditScreen(context: viewModel.context)
        }
    }
}
