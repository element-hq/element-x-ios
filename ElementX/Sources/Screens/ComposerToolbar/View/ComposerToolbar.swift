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
    @ScaledMetric private var sendButtonIconSize = 16

    var body: some View {
        VStack(spacing: 8) {
            topBar
            if context.composerActionsEnabled {
                bottomBar
            }
        }
        .alert(item: $context.alertInfo)
    }

    private var topBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            if !context.composerActionsEnabled {
                RoomAttachmentPicker(context: context)
                    .padding(.bottom, 5) // centre align with the send button
            }
            messageComposer
                .environmentObject(context)
            if !context.composerActionsEnabled {
                sendButton
            }
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .bottom, spacing: 10) {
            Button {
                context.composerActionsEnabled = false
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.compound.headingLG)
                    .foregroundColor(.compound.textActionPrimary)
            }
            .accessibilityIdentifier(A11yIdentifiers.roomScreen.composerToolbar.closeFormattingOptions)
            .padding(.bottom, 5) // centre align with the send button
            FormattingToolbar(formatItems: context.formatItems) { action in
                context.send(viewAction: .composerAction(action: action.composerAction))
            }
            sendButton
        }
    }

    private var sendButton: some View {
        Button {
            context.send(viewAction: .sendMessage)
        } label: {
            submitButtonImage
                .symbolVariant(.fill)
                .font(.compound.bodyLG)
                .foregroundColor(context.viewState.sendButtonDisabled ? .compound.iconDisabled : .global.white)
                .background {
                    Circle()
                        .foregroundColor(context.viewState.sendButtonDisabled ? .clear : .compound.iconAccentTertiary)
                }
        }
        .disabled(context.viewState.sendButtonDisabled)
        .animation(.linear(duration: 0.1), value: context.viewState.sendButtonDisabled)
        .keyboardShortcut(.return, modifiers: [.command])
        .padding([.vertical, .trailing], 6)
    }
    
    private var messageComposer: some View {
        MessageComposer(plainText: $context.composerPlainText,
                        composerView: composerView,
                        mode: context.viewState.composerMode,
                        resizeBehaviorEnabled: context.viewState.bindings.composerActionsEnabled) {
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

    private var submitButtonImage: some View {
        // ZStack with opacity so the button size is consistent.
        ZStack {
            Image(systemName: "checkmark")
                .opacity(context.viewState.composerMode.isEdit ? 1 : 0)
                .fontWeight(.medium)
                .accessibilityLabel(L10n.actionConfirm)
                .accessibilityHidden(!context.viewState.composerMode.isEdit)
            Image(asset: Asset.Images.timelineComposerSendMessage)
                .resizable()
                .frame(width: sendButtonIconSize, height: sendButtonIconSize)
                .padding(EdgeInsets(top: 7, leading: 8, bottom: 7, trailing: 6))
                .opacity(context.viewState.composerMode.isEdit ? 0 : 1)
                .accessibilityLabel(L10n.actionSend)
                .accessibilityHidden(context.viewState.composerMode.isEdit)
        }
    }

    private class ItemProviderHelper: WysiwygItemProviderHelper {
        func isPasteSupported(for itemProvider: NSItemProvider) -> Bool {
            itemProvider.isSupportedForPasteOrDrop
        }
    }
}

struct ComposerToolbar_Previews: PreviewProvider {
    static var previews: some View {
        ComposerToolbar.mock()
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
