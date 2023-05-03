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

struct RoomAttachmentPicker: View {
    @ObservedObject var context: RoomScreenViewModel.Context
    
    @State private var showAttachmentPopover = false
    @State private var sheetContentHeight = CGFloat(0)
    
    var body: some View {
        Button {
            showAttachmentPopover = true
        } label: {
            Image(systemName: "plus.circle.fill")
                .font(.compound.headingLG)
                .foregroundColor(.element.accent)
        }
        .popover(isPresented: $showAttachmentPopover) {
            VStack(alignment: .leading, spacing: 0.0) {
                Button {
                    showAttachmentPopover = false
                    context.send(viewAction: .displayMediaPicker)
                } label: {
                    Label(L10n.screenRoomAttachmentSourceGallery, systemImage: "photo.fill")
                        .labelStyle(EqualIconWidthLabelStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                
                Button {
                    showAttachmentPopover = false
                    context.send(viewAction: .displayDocumentPicker)
                } label: {
                    Label(L10n.screenRoomAttachmentSourceFiles, systemImage: "paperclip")
                        .labelStyle(EqualIconWidthLabelStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
                
                Button {
                    showAttachmentPopover = false
                    context.send(viewAction: .displayCameraPicker)
                } label: {
                    Label(L10n.screenRoomAttachmentSourceCamera, systemImage: "camera.fill")
                        .labelStyle(EqualIconWidthLabelStyle())
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }
            }
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
            .presentationDragIndicator(.visible)
            .tint(.element.accent)
        }
    }
}

private struct EqualIconWidthLabelStyle: LabelStyle {
    @ScaledMetric private var menuIconSize = 24.0
    
    func makeBody(configuration: Configuration) -> some View {
        HStack {
            configuration
                .icon
                .frame(width: menuIconSize, height: menuIconSize)
            configuration.title
        }
    }
}
