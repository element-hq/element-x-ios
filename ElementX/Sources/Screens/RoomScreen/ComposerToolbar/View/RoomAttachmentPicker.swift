//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
            CompoundIcon(\.plus,
                         size: Compound.supportsGlass ? .medium : .small,
                         relativeTo: .compound.headingLG)
        }
        .buttonStyle(ComposerToolbarButtonStyle())
        .accessibilityLabel(L10n.actionAddToTimeline)
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
    }
    
    var menuContent: some View {
        VStack(alignment: .leading, spacing: 0.0) {
            Button {
                context.send(viewAction: .enableTextFormatting)
            } label: {
                Label(L10n.screenRoomAttachmentTextFormatting, icon: \.textFormatting)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerTextFormatting)
            
            Button {
                context.send(viewAction: .attach(.poll))
            } label: {
                Label(L10n.screenRoomAttachmentSourcePoll, icon: \.polls)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerPoll)
            
            if context.viewState.isLocationSharingEnabled {
                Button {
                    context.send(viewAction: .attach(.location))
                } label: {
                    Label(L10n.screenRoomAttachmentSourceLocation, icon: \.locationPin)
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerLocation)
            }
            
            Button {
                context.send(viewAction: .attach(.file))
            } label: {
                Label(L10n.screenRoomAttachmentSourceFiles, icon: \.attachment)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerDocuments)
            
            Button {
                context.send(viewAction: .attach(.photoLibrary))
            } label: {
                Label(L10n.screenRoomAttachmentSourceGallery, icon: \.image)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary)
            
            Button {
                context.send(viewAction: .attach(.camera))
            } label: {
                Label(L10n.screenRoomAttachmentSourceCamera, icon: \.takePhoto)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerCamera)
        }
    }
}

struct RoomAttachmentPicker_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ComposerToolbarViewModel(roomProxy: JoinedRoomProxyMock(.init()),
                                                    wysiwygViewModel: WysiwygComposerViewModel(),
                                                    completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                    mediaProvider: MediaProviderMock(configuration: .init()),
                                                    mentionDisplayHelper: ComposerMentionDisplayHelper.mock,
                                                    appSettings: ServiceLocator.shared.settings,
                                                    analyticsService: ServiceLocator.shared.analytics,
                                                    composerDraftService: ComposerDraftServiceMock(.init()))

    static var previews: some View {
        RoomAttachmentPicker(context: viewModel.context)
    }
}
