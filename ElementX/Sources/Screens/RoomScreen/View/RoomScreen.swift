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
    
    var body: some View {
        VStack(spacing: 0.0) {
            TimelineView()
                .environmentObject(context)
            
            MessageComposer(text: $context.composerText,
                            focused: $context.composerFocused,
                            sendingDisabled: context.viewState.sendButtonDisabled,
                            type: context.viewState.composerType) {
                sendMessage()
            } replyCancellationAction: {
                context.send(viewAction: .cancelReply)
            }
            .padding()
            // Remove this once we have local echoes
            .opacity(context.viewState.messageComposerDisabled ? 0.5 : 1.0)
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                RoomHeaderView(context: context)
            }
        }
        .alert(item: $context.alertInfo) { $0.alert }
    }
    
    private func sendMessage() {
        guard !context.viewState.sendButtonDisabled else {
            return
        }
        
        context.send(viewAction: .sendMessage)
    }
}

// MARK: - Previews

struct RoomScreen_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }
    
    @ViewBuilder
    static var body: some View {
        let viewModel = RoomScreenViewModel(timelineController: MockRoomTimelineController(),
                                            timelineViewFactory: RoomTimelineViewFactory(),
                                            roomName: "Preview room")
        
        NavigationView {
            RoomScreen(context: viewModel.context)
        }
    }
}
