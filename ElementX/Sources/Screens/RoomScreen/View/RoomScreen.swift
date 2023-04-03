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

import SwiftUI

struct RoomScreen: View {
    @ObservedObject var context: RoomScreenViewModel.Context
    @State private var showReactionsMenuForItemId = ""
    
    var body: some View {
        timeline
            .background(Color.element.background.ignoresSafeArea()) // Kills the toolbar translucency.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                HStack(spacing: 4.0) {
                    if context.viewState.mediaUploadingFlowEnabled {
                        sendAttachmentButton
                    }
                    
                    messageComposer
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarRole(.editor) // Hide the back button title.
            .toolbarBackground(.visible, for: .navigationBar) // Fix the toolbar's background.
            .overlay { loadingIndicator }
            .alert(item: $context.alertInfo) { $0.alert }
            .sheet(item: $context.debugInfo) { TimelineItemDebugView(info: $0) }
            .task(id: context.viewState.roomId) {
                // Give a couple of seconds for items to load and to see them.
                try? await Task.sleep(for: .seconds(2))
                
                guard !Task.isCancelled else { return }
                context.send(viewAction: .markRoomAsRead)
            }
    }
    
    private var timeline: some View {
        TimelineView()
            .id(context.viewState.roomId)
            .environmentObject(context)
            .timelineStyle(context.viewState.timelineStyle)
            .overlay(alignment: .bottomTrailing) { scrollToBottomButton }
    }
    
    private var messageComposer: some View {
        MessageComposer(text: $context.composerText,
                        focused: $context.composerFocused,
                        sendingDisabled: context.viewState.sendButtonDisabled,
                        type: context.viewState.composerMode) {
            sendMessage()
        } replyCancellationAction: {
            context.send(viewAction: .cancelReply)
        } editCancellationAction: {
            context.send(viewAction: .cancelEdit)
        }
    }
    
    private var scrollToBottomButton: some View {
        Button { context.viewState.scrollToBottomPublisher.send(()) } label: {
            Image(systemName: "chevron.down")
                .font(.element.body)
                .fontWeight(.semibold)
                .foregroundColor(.element.secondaryContent)
                .padding(13)
                .offset(y: 1)
                .background {
                    Circle()
                        .fill(Color.element.background)
                        // Intentionally using system primary colour to get white/black.
                        .shadow(color: .primary.opacity(0.33), radius: 2.0)
                }
                .padding()
        }
        .opacity(context.scrollToBottomButtonVisible ? 1.0 : 0.0)
        .accessibilityHidden(!context.scrollToBottomButtonVisible)
        .animation(.elementDefault, value: context.scrollToBottomButtonVisible)
    }
    
    @ViewBuilder
    private var loadingIndicator: some View {
        if context.viewState.showLoading {
            ProgressView()
                .progressViewStyle(.circular)
                .tint(.element.primaryContent)
                .padding(16)
                .background(Color.element.quinaryContent)
                .cornerRadius(8)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        // .principal + .primaryAction works better than .navigation leading + trailing
        // as the latter disables interaction in the action button for rooms with long names
        ToolbarItem(placement: .principal) {
            RoomHeaderView(context: context)
        }
    }
    
    private var sendAttachmentButton: some View {
        Menu {
            Button {
                context.send(viewAction: .displayDocumentPicker)
            } label: {
                Label(UntranslatedL10n.mediaUploadDocumentPicker, systemImage: "doc")
            }
            Button {
                context.send(viewAction: .displayMediaPicker)
            } label: {
                Label(UntranslatedL10n.mediaUploadPhotoAndVideoPicker, systemImage: "photo")
            }
            Button {
                context.send(viewAction: .displayCameraPicker)
            } label: {
                Label(UntranslatedL10n.mediaUploadCameraPicker, systemImage: "camera")
            }
        } label: {
            Image(systemName: "plus.circle")
                .font(.element.title1)
                .foregroundColor(.element.brand)
        }
    }
    
    private func sendMessage() {
        guard !context.viewState.sendButtonDisabled else { return }
        context.send(viewAction: .sendMessage)
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                               mediaProvider: MockMediaProvider(),
                                               roomName: "Preview room")
    
    static var previews: some View {
        NavigationStack {
            RoomScreen(context: viewModel.context)
        }
    }
}
