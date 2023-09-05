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

import SwiftUI
import WysiwygComposer

struct RoomAttachmentPicker: View {
    @ObservedObject var context: ComposerToolbarViewModel.Context
    @Environment(\.isPresented) var isPresented
    
    @State private var sheetContentHeight = CGFloat(0)
    
    var body: some View {
        Button {
            context.showAttachmentPopover = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.compound.headingLG)
                .foregroundColor(.compound.textActionPrimary)
        }
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.composerToolbar.openComposeOptions)
        .popover(isPresented: $context.showAttachmentPopover) {
            VStack(alignment: .leading, spacing: 0.0) {
                Button {
                    context.showAttachmentPopover = false
                    context.send(viewAction: .displayMediaPicker)
                } label: {
                    PickerLabel(title: L10n.screenRoomAttachmentSourceGallery, icon: Image(systemName: "photo.fill"))
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerPhotoLibrary)
                
                Button {
                    context.showAttachmentPopover = false
                    context.send(viewAction: .displayDocumentPicker)
                } label: {
                    PickerLabel(title: L10n.screenRoomAttachmentSourceFiles, icon: Image(systemName: "paperclip"))
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerDocuments)
                
                Button {
                    context.showAttachmentPopover = false
                    context.send(viewAction: .displayCameraPicker)
                } label: {
                    PickerLabel(title: L10n.screenRoomAttachmentSourceCamera, icon: Image(systemName: "camera.fill"))
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerCamera)

                Button {
                    context.showAttachmentPopover = false
                    context.send(viewAction: .displayLocationPicker)
                } label: {
                    PickerLabel(title: L10n.screenRoomAttachmentSourceLocation, icon: Image(asset: Asset.Images.locationPin))
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerLocation)

                Button {
                    context.showAttachmentPopover = false
                    context.send(viewAction: .displayPollForm)
                } label: {
                    PickerLabel(title: L10n.screenRoomAttachmentSourcePoll, icon: Image(asset: Asset.Images.timelinePollAttachment))
                }
                .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerPoll)

                if ServiceLocator.shared.settings.richTextEditorEnabled {
                    Button {
                        context.showAttachmentPopover = false
                        context.send(viewAction: .enableTextFormatting)
                    } label: {
                        PickerLabel(title: L10n.screenRoomAttachmentTextFormatting, icon: Image(asset: Asset.Images.textFormat))
                    }
                    .accessibilityIdentifier(A11yIdentifiers.roomScreen.attachmentPickerTextFormatting)
                }
            }
            .padding(.top, isPresented ? 20 : 0)
            .background {
                // This is done in the background otherwise GeometryReader tends to expand to
                // all the space given to it like color or shape.
                GeometryReader { proxy in
                    Color.clear
                        .onAppear {
                            sheetContentHeight = proxy.size.height
                        }
                }
            }
            .presentationDetents([.height(sheetContentHeight)])
            .presentationBackground(Color.compound.bgCanvasDefault)
            .presentationDragIndicator(.visible)
        }
    }
    
    private struct PickerLabel: View {
        let title: String
        let icon: Image

        init(title: String, icon: Image) {
            self.title = title
            self.icon = icon
        }
        
        var body: some View {
            Label {
                Text(title)
            } icon: {
                icon
            }
            .labelStyle(FixedIconSizeLabelStyle())
            .multilineTextAlignment(.leading)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
        }
    }
}

struct RoomAttachmentPicker_Previews: PreviewProvider {
    static let viewModel = ComposerToolbarViewModel(wysiwygViewModel: WysiwygComposerViewModel())

    static var previews: some View {
        RoomAttachmentPicker(context: viewModel.context)
    }
}
