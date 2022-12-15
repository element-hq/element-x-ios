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
            .safeAreaInset(edge: .bottom) { messageComposer }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .overlay { loadingIndicator }
            .alert(item: $context.alertInfo) { $0.alert }
            .sheet(item: $context.debugInfo) { DebugScreen(info: $0) }
    }
    
    var timeline: some View {
        TimelineView()
            .id(context.viewState.roomId)
            .environmentObject(context)
            .timelineStyle(settings.timelineStyle)
            .overlay(alignment: .bottomTrailing) { scrollToBottomButton }
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
    
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
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
            RoomScreen(context: viewModel.context)
        }
    }
}
