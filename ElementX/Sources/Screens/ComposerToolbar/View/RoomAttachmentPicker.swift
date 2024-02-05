//
// Copyright 2023 New Vector Ltd
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
import WysiwygComposer

struct RoomAttachmentPicker: View {
    @ObservedObject var context: ComposerToolbarViewModel.Context
    
    var body: some View {
        // Use a menu instead of the popover/sheet shown in Figma because overriding the colour scheme
        // results in a rendering bug on 17.1: https://github.com/element-hq/element-x-ios/issues/2157
        Menu {
            menuContent
        } label: {
            CompoundIcon(asset: Asset.Images.composerAttachment, size: .custom(30), relativeTo: .title)
                .scaledPadding(7, relativeTo: .title)
        }
        .buttonStyle(RoomAttachmentPickerButtonStyle())
        .accessibilityLabel(L10n.actionAddToTimeline)
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
    }
    
    var menuContent: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            Button {
                context.send(viewAction: .attach(.photoLibrary))
            } label: {
                Label(L10n.screenRoomAttachmentSourceGallery, icon: \.image)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary)
            
            Button {
                context.send(viewAction: .attach(.file))
            } label: {
                Label(L10n.screenRoomAttachmentSourceFiles, icon: \.attachment)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerDocuments)
            
            Button {
                context.send(viewAction: .attach(.camera))
            } label: {
                Label(L10n.screenRoomAttachmentSourceCamera, icon: \.takePhoto)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerCamera)

            Button {
                context.send(viewAction: .attach(.location))
            } label: {
                Label(L10n.screenRoomAttachmentSourceLocation, icon: \.locationPin)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerLocation)

            Button {
                context.send(viewAction: .attach(.poll))
            } label: {
                Label(L10n.screenRoomAttachmentSourcePoll, icon: \.polls)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerPoll)

            if ServiceLocator.shared.settings.richTextEditorEnabled {
                Button {
                    context.send(viewAction: .enableTextFormatting)
                } label: {
                    Label(L10n.screenRoomAttachmentTextFormatting, icon: \.textFormatting)
                        .labelStyle(.menuSheet)
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerTextFormatting)
            }
        }
    }
}

private struct RoomAttachmentPickerButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundStyle(configuration.isPressed ? .compound.bgActionPrimaryPressed : .compound.bgActionPrimaryRest)
    }
}

struct RoomAttachmentPicker_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ComposerToolbarViewModel(wysiwygViewModel: WysiwygComposerViewModel(),
                                                    completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                    mediaProvider: MockMediaProvider(),
                                                    appSettings: ServiceLocator.shared.settings,
                                                    mentionDisplayHelper: ComposerMentionDisplayHelper.mock)

    static var previews: some View {
        RoomAttachmentPicker(context: viewModel.context)
    }
}
