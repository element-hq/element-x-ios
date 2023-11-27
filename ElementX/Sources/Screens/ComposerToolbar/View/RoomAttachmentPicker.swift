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
    @Environment(\.isPresented) var isPresented

    @State private var sheetContentFrame: CGRect = .zero
    
    var body: some View {
        Button {
            context.showAttachmentPopover = true
        } label: {
            CompoundIcon(asset: Asset.Images.composerAttachment, size: .custom(30), relativeTo: .title)
                .scaledPadding(7, relativeTo: .title)
        }
        .buttonStyle(RoomAttachmentPickerButtonStyle())
        .accessibilityLabel(L10n.actionAddToTimeline)
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        .popover(isPresented: $context.showAttachmentPopover) {
            menuContent
                .padding(.top, isPresented ? 20 : 0)
                .readFrame($sheetContentFrame)
                .presentationDetents([.height(sheetContentFrame.height)])
                .presentationBackground(.compound.bgCanvasDefault)
                .presentationDragIndicator(.visible)
        }
    }
    
    var menuContent: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            Button {
                context.showAttachmentPopover = false
                context.send(viewAction: .displayMediaPicker)
            } label: {
                Label(L10n.screenRoomAttachmentSourceGallery, icon: \.image)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary)
            
            Button {
                context.showAttachmentPopover = false
                context.send(viewAction: .displayDocumentPicker)
            } label: {
                Label(L10n.screenRoomAttachmentSourceFiles, iconAsset: Asset.Images.attachment)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerDocuments)
            
            Button {
                context.showAttachmentPopover = false
                context.send(viewAction: .displayCameraPicker)
            } label: {
                Label(L10n.screenRoomAttachmentSourceCamera, iconAsset: Asset.Images.takePhoto)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerCamera)

            Button {
                context.showAttachmentPopover = false
                context.send(viewAction: .displayLocationPicker)
            } label: {
                Label(L10n.screenRoomAttachmentSourceLocation, iconAsset: Asset.Images.addLocation)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerLocation)

            Button {
                context.showAttachmentPopover = false
                context.send(viewAction: .displayNewPollForm)
            } label: {
                Label(L10n.screenRoomAttachmentSourcePoll, iconAsset: Asset.Images.polls)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerPoll)

            if ServiceLocator.shared.settings.richTextEditorEnabled {
                Button {
                    context.showAttachmentPopover = false
                    context.send(viewAction: .enableTextFormatting)
                } label: {
                    Label(L10n.screenRoomAttachmentTextFormatting, iconAsset: Asset.Images.textFormat)
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
            // Disable animations to fix a bug when the system is in Light mode but the app in Dark mode. For some
            // reason the animation causes a glitch with sheet's colour scheme when there are presentation detents.
            // https://github.com/vector-im/element-x-ios/issues/2157
            .animation(.noAnimation, value: configuration.isPressed)
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
