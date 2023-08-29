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

struct ComposerToolbar: View {
    @ObservedObject var context: ComposerToolbarViewModel.Context
    let wysiwygViewModel: WysiwygComposerViewModel
    let keyCommandHandler: KeyCommandHandler

    @FocusState private var composerFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 10) {
            RoomAttachmentPicker(context: context)
                .padding(.bottom, 5) // centre align with the send button
            messageComposer
                .environmentObject(context)
        }
    }
    
    private var messageComposer: some View {
        MessageComposer(plainText: $context.composerPlainText,
                        composerView: composerView,
                        sendingDisabled: context.viewState.sendButtonDisabled,
                        mode: context.viewState.composerMode) {
            context.send(viewAction: .sendMessage)
        } pasteAction: { provider in
            context.send(viewAction: .handlePasteOrDrop(provider: provider))
        } replyCancellationAction: {
            context.send(viewAction: .cancelReply)
        } editCancellationAction: {
            context.send(viewAction: .cancelEdit)
        } onAppearAction: {
            context.send(viewAction: .composerAppeared)
        }
        .focused($composerFocused)
        .onChange(of: context.composerFocused) { newValue in
            guard composerFocused != newValue else { return }

            composerFocused = newValue
        }
        .onChange(of: composerFocused) { newValue in
            context.composerFocused = newValue
        }
    }
    
    private var composerView: WysiwygComposerView {
        WysiwygComposerView(placeholder: L10n.richTextEditorComposerPlaceholder,
                            viewModel: wysiwygViewModel,
                            itemProviderHelper: ItemProviderHelper(),
                            keyCommandHandler: keyCommandHandler) { provider in
            context.send(viewAction: .handlePasteOrDrop(provider: provider))
        }
    }

    private class ItemProviderHelper: WysiwygItemProviderHelper {
        func isPasteSupported(for itemProvider: NSItemProvider) -> Bool {
            itemProvider.isSupportedForPasteOrDrop
        }
    }
}

// MARK: - Mock

extension ComposerToolbar {
    static func mock() -> ComposerToolbar {
        let wysiwygViewModel = WysiwygComposerViewModel()
        let composerViewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel)
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommandHandler: { _ in false })
    }
}
