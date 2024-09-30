//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
                context.send(viewAction: .enableTextFormatting)
            } label: {
                Label(L10n.screenRoomAttachmentTextFormatting, icon: \.textFormatting)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerTextFormatting)
            
            Button {
                context.send(viewAction: .attach(.poll))
            } label: {
                Label(L10n.screenRoomAttachmentSourcePoll, icon: \.polls)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerPoll)
            
            Button {
                context.send(viewAction: .attach(.location))
            } label: {
                Label(L10n.screenRoomAttachmentSourceLocation, icon: \.locationPin)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerLocation)
            
            Button {
                context.send(viewAction: .attach(.file))
            } label: {
                Label(L10n.screenRoomAttachmentSourceFiles, icon: \.attachment)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerDocuments)
            
            Button {
                context.send(viewAction: .attach(.photoLibrary))
            } label: {
                Label(L10n.screenRoomAttachmentSourceGallery, icon: \.image)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary)
            
            Button {
                context.send(viewAction: .attach(.camera))
            } label: {
                Label(L10n.screenRoomAttachmentSourceCamera, icon: \.takePhoto)
                    .labelStyle(.menuSheet)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerCamera)
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
                                                    mentionDisplayHelper: ComposerMentionDisplayHelper.mock,
                                                    analyticsService: ServiceLocator.shared.analytics,
                                                    composerDraftService: ComposerDraftServiceMock())

    static var previews: some View {
        RoomAttachmentPicker(context: viewModel.context)
    }
}
