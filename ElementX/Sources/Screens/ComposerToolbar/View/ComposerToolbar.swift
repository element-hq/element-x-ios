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

struct ComposerToolbar: View {
    @ObservedObject var context: ComposerToolbarViewModel.Context
    @FocusState private var composerFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            RoomAttachmentPicker(context: context)
                .padding(.bottom, 5) // centre align with the send button
            messageComposer
                .environmentObject(context)
        }
        .onChange(of: context.composerFocused) { newValue in
            composerFocused = newValue
        }
        .onChange(of: composerFocused) { newValue in
            context.composerFocused = newValue
        }
    }
    
    private var messageComposer: some View {
        MessageComposer(text: $context.composerText,
                        focused: $composerFocused,
                        sendingDisabled: context.viewState.sendButtonDisabled,
                        mode: context.viewState.composerMode) {
            sendMessage()
        } pasteAction: { provider in
            context.send(viewAction: .handlePasteOrDrop(provider: provider))
        } replyCancellationAction: {
            context.send(viewAction: .cancelReply)
        } editCancellationAction: {
            context.send(viewAction: .cancelEdit)
        }
    }

    private func sendMessage() {
        guard !context.viewState.sendButtonDisabled else { return }
        context.send(viewAction: .sendMessage(message: context.composerText, mode: context.viewState.composerMode))
    }
}
