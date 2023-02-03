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
    @ObservedObject private var settings = ServiceLocator.shared.settings
    @ObservedObject var context: RoomScreenViewModel.Context
    @State private var showReactionsMenuForItemId = ""
    
    var body: some View {
        timeline
            .background(Color.element.background.ignoresSafeArea()) // Kills the toolbar translucency.
            .overlay(alignment: .top) { encryptionBanner } // Overlay for now, safeAreaInset breaks timeline scroll offset.
            .animation(.spring(), value: context.viewState.showEncryptionBanner)
            .safeAreaInset(edge: .bottom, spacing: 0) { messageComposer }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .toolbarRole(.editor) // Hide the back button title.
            .toolbarBackground(.visible, for: .navigationBar) // Fix the toolbar's background.
            .overlay { loadingIndicator }
            .alert(item: $context.alertInfo) { $0.alert }
            .sheet(item: $context.debugInfo) { DebugScreen(info: $0) }
            .task(id: context.viewState.roomId) {
                // Give a couple of seconds for items to load and to see them.
                try? await Task.sleep(for: .seconds(2))
                
                guard !Task.isCancelled else { return }
                context.send(viewAction: .markRoomAsRead)
            }
    }
    
    var timeline: some View {
        TimelineView()
            .id(context.viewState.roomId)
            .environmentObject(context)
            .timelineStyle(settings.timelineStyle)
            .overlay(alignment: .bottomTrailing) { scrollToBottomButton }
    }
    
    @ViewBuilder
    var encryptionBanner: some View {
        if context.viewState.showEncryptionBanner {
            VStack(alignment: .leading, spacing: 4) {
                Label {
                    Text("Unable to decrypt all messages")
                        .foregroundColor(.element.primaryContent)
                } icon: {
                    Image(systemName: "lock.shield")
                        .foregroundColor(.element.background)
                        .padding(4)
                        .background(Color.element.tertiaryContent)
                        .cornerRadius(5)
                }
                .font(.element.bodyBold)
                
                Text("Accessing your encrypted message history is not fully supported yet.")
                    .font(.element.subheadline)
                    .foregroundColor(.element.secondaryContent)
                    .padding(.bottom, 8)
                
                Button(ElementL10n.globalRetry) {
                    context.send(viewAction: .retryDecryption)
                }
                .buttonStyle(.elementCapsuleProminent)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.element.system)
            }
            .padding([.horizontal, .top], 16)
            .background(Color.element.background)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }
    
    var messageComposer: some View {
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
        .padding()
    }
    
    var scrollToBottomButton: some View {
        Button { context.viewState.scrollToBottomPublisher.send(()) } label: {
            Image(uiImage: Asset.Images.timelineScrollToBottom.image)
                .shadow(radius: 2.0)
                .padding()
        }
        .opacity(context.scrollToBottomButtonVisible ? 1.0 : 0.0)
        .animation(.elementDefault, value: context.scrollToBottomButtonVisible)
    }
    
    @ViewBuilder
    var loadingIndicator: some View {
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
    var toolbar: some ToolbarContent {
        // .principal + .primaryAction works better than .navigation leading + trailing
        // as the latter disables interaction in the action button for rooms with long names
        ToolbarItem(placement: .principal) {
            RoomHeaderView(context: context)
        }
    }
    
    private func sendMessage() {
        guard !context.viewState.sendButtonDisabled else { return }
        context.send(viewAction: .sendMessage)
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            mediaProvider: MockMediaProvider(),
                                            roomName: "Preview room")
        
        NavigationView {
            RoomScreen(context: viewModel.context).encryptionBanner
                .padding()
        }
    }
}
