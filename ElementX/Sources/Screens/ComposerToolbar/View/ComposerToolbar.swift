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

import Compound
import SwiftUI
import WysiwygComposer

struct ComposerToolbar: View {
    @ObservedObject var context: ComposerToolbarViewModel.Context
    let wysiwygViewModel: WysiwygComposerViewModel
    let keyCommandHandler: KeyCommandHandler

    @FocusState private var composerFocused: Bool
    @ScaledMetric private var sendButtonIconSize = 16
    @ScaledMetric(relativeTo: .title) private var closeRTEButtonSize = 30
    
    @State private var frame: CGRect = .zero

    var body: some View {
        VStack(spacing: 8) {
            topBar
            if context.composerActionsEnabled {
                bottomBar
            }
        }
        .background {
            ViewFrameReader(frame: $frame)
        }
        .overlay(alignment: .bottom) {
            if context.viewState.areSuggestionsEnabled {
                suggestionView
                    .offset(y: -frame.height)
            }
        }
        .alert(item: $context.alertInfo)
    }
    
    private var suggestionView: some View {
        CompletionSuggestionView(imageProvider: context.imageProvider, items: context.viewState.suggestions)
    }

    private var topBar: some View {
        HStack(alignment: .bottom, spacing: 5) {
            if !context.composerActionsEnabled {
                RoomAttachmentPicker(context: context)
            }

            messageComposer
                .environmentObject(context)
                .onTapGesture {
                    guard !composerFocused else { return }
                    composerFocused = true
                }
                .padding(.leading, context.composerActionsEnabled ? 7 : 0)
                .padding(.trailing, context.composerActionsEnabled ? 4 : 0)

            if !context.composerActionsEnabled {
                sendButton
                    .padding(.leading, 3)
            }
        }
    }

    private var bottomBar: some View {
        HStack(alignment: .center, spacing: 9) {
            closeRTEButton

            FormattingToolbar(formatItems: context.formatItems) { action in
                context.send(viewAction: .composerAction(action: action.composerAction))
            }

            sendButton
                .padding(.leading, 7)
        }
    }

    private var closeRTEButton: some View {
        Button {
            context.composerActionsEnabled = false
            context.composerExpanded = false
        } label: {
            Image(Asset.Images.closeRte.name)
                .resizable()
                .scaledToFit()
                .frame(width: closeRTEButtonSize, height: closeRTEButtonSize)
                .padding(7)
        }
        .accessibilityLabel(L10n.actionClose)
        .accessibilityIdentifier(A11yIdentifiers.roomScreen.composerToolbar.closeFormattingOptions)
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
                .padding(4)
        }
        .disabled(context.viewState.sendButtonDisabled)
        .animation(.linear(duration: 0.1).disabledDuringTests(), value: context.viewState.sendButtonDisabled)
        .keyboardShortcut(.return, modifiers: [.command])
    }
    
    private var messageComposer: some View {
        MessageComposer(composerView: composerView,
                        mode: context.viewState.composerMode,
                        showResizeGrabber: context.viewState.bindings.composerActionsEnabled,
                        isExpanded: $context.composerExpanded) {
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
    
    private var placeholder: String {
        switch context.viewState.composerMode {
        case .reply(_, _, let isThread):
            return isThread ? L10n.actionReplyInThread : L10n.richTextEditorComposerPlaceholder
        default:
            return L10n.richTextEditorComposerPlaceholder
        }
    }
    
    private var composerView: WysiwygComposerView {
        WysiwygComposerView(placeholder: placeholder,
                            placeholderColor: .compound.textSecondary,
                            viewModel: wysiwygViewModel,
                            itemProviderHelper: ItemProviderHelper(),
                            keyCommandHandler: keyCommandHandler) { provider in
            context.send(viewAction: .handlePasteOrDrop(provider: provider))
        }
    }

    private var submitButtonImage: some View {
        // ZStack with opacity so the button size is consistent.
        ZStack {
            CompoundIcon(\.check)
                .opacity(context.viewState.composerMode.isEdit ? 1 : 0)
                .accessibilityLabel(L10n.actionConfirm)
                .accessibilityHidden(!context.viewState.composerMode.isEdit)
            Image(asset: Asset.Images.sendMessage)
                .resizable()
                .frame(width: sendButtonIconSize, height: sendButtonIconSize)
                .padding(EdgeInsets(top: 10, leading: 11, bottom: 10, trailing: 9))
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

struct ComposerToolbar_Previews: PreviewProvider, TestablePreview {
    static let wysiwygViewModel = WysiwygComposerViewModel()
    static let composerViewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                            completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init(suggestions: suggestions)),
                                                            mediaProvider: MockMediaProvider())
    static let suggestions: [SuggestionItem] = [.user(item: MentionSuggestionItem(id: "@user_mention_1:matrix.org", displayName: "User 1", avatarURL: nil)),
                                                .user(item: MentionSuggestionItem(id: "@user_mention_2:matrix.org", displayName: "User 2", avatarURL: URL.documentsDirectory))]
    
    static var previews: some View {
        ComposerToolbar.mock()
        
        // Putting them is VStack allows the completion suggestion preview to work properly in tests
        VStack {
            // The mock functon can't be used in this context because it does not hold a reference to the view model, losing the combine subscriptions
            ComposerToolbar(context: composerViewModel.context,
                            wysiwygViewModel: wysiwygViewModel,
                            keyCommandHandler: { _ in false })
        }
        .previewDisplayName("With Suggestions")
    }
}

// MARK: - Mock

extension ComposerToolbar {
    static func mock() -> ComposerToolbar {
        let wysiwygViewModel = WysiwygComposerViewModel()
        let composerViewModel = ComposerToolbarViewModel(wysiwygViewModel: wysiwygViewModel,
                                                         completionSuggestionService: CompletionSuggestionServiceMock(configuration: .init()),
                                                         mediaProvider: MockMediaProvider())
        return ComposerToolbar(context: composerViewModel.context,
                               wysiwygViewModel: wysiwygViewModel,
                               keyCommandHandler: { _ in false })
    }
}
