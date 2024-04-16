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

enum ComposerToolbarVoiceMessageAction {
    case startRecording
    case stopRecording
    case cancelRecording
    case deleteRecording
    case startPlayback
    case pausePlayback
    case scrubPlayback(scrubbing: Bool)
    case seekPlayback(progress: Double)
    case send
}

enum ComposerToolbarViewModelAction {
    case sendMessage(plain: String, html: String?, mode: RoomScreenComposerMode, intentionalMentions: IntentionalMentions)
    case attach(ComposerAttachmentType)

    case handlePasteOrDrop(provider: NSItemProvider)

    case composerModeChanged(mode: RoomScreenComposerMode)
    case composerFocusedChanged(isFocused: Bool)
    
    case voiceMessage(ComposerToolbarVoiceMessageAction)
    
    case contentChanged(isEmpty: Bool)
}

enum ComposerToolbarViewAction {
    case composerAppeared
    case sendMessage
    case cancelReply
    case cancelEdit
    case attach(ComposerAttachmentType)
    case handlePasteOrDrop(provider: NSItemProvider)
    case enableTextFormatting
    case composerAction(action: ComposerAction)
    case selectedSuggestion(_ suggestion: SuggestionItem)
    
    case voiceMessage(ComposerToolbarVoiceMessageAction)
}

enum ComposerAttachmentType {
    case camera
    case photoLibrary
    case file
    case location
    case poll
}

struct ComposerToolbarViewState: BindableState {
    var composerMode: RoomScreenComposerMode = .default
    var composerEmpty = true
    var suggestions: [SuggestionItem] = []
    var audioPlayerState: AudioPlayerState
    var audioRecorderState: AudioRecorderState
    
    var bindings: ComposerToolbarViewStateBindings

    var isUploading: Bool {
        switch composerMode {
        case .previewVoiceMessage(_, _, let isUploading):
            return isUploading
        default:
            return false
        }
    }

    var showSendButton: Bool {
        switch composerMode {
        case .recordVoiceMessage:
            return false
        case .previewVoiceMessage:
            return true
        default:
            if ServiceLocator.shared.settings.richTextEditorEnabled {
                return !composerEmpty
            } else {
                return !bindings.composerPlainText.isEmpty
            }
        }
    }
    
    var sendButtonDisabled: Bool {
        if case .previewVoiceMessage = composerMode {
            return false
        }
        
        if ServiceLocator.shared.settings.richTextEditorEnabled {
            return composerEmpty
        } else {
            return bindings.composerPlainText.isEmpty
        }
    }
    
    var isVoiceMessageModeActivated: Bool {
        switch composerMode {
        case .recordVoiceMessage, .previewVoiceMessage:
            return true
        default:
            return false
        }
    }
}

struct ComposerToolbarViewStateBindings {
    var composerPlainText = ""
    var composerFocused = false
    var composerActionsEnabled = false
    var composerExpanded = false
    var formatItems: [FormatItem] = .init()
    var alertInfo: AlertInfo<UUID>?
}

/// An item in the toolbar
struct FormatItem {
    /// The type of the item
    let type: FormatType
    /// The state of the item
    let state: ActionState
}

/// The types of formatting actions
enum FormatType {
    case bold
    case italic
    case underline
    case strikeThrough
    case link
    case unorderedList
    case orderedList
    case indent
    case unindent
    case inlineCode
    case codeBlock
    case quote
}

extension FormatType: CaseIterable, Identifiable {
    var id: Self { self }
}

extension FormatItem: Identifiable {
    var id: FormatType { type }
}

extension FormatItem {
    /// The icon to display in the formatting toolbar.
    var icon: KeyPath<CompoundIcons, Image> {
        switch type {
        case .bold:
            return \.bold
        case .italic:
            return \.italic
        case .underline:
            return \.underline
        case .strikeThrough:
            return \.strikethrough
        case .unorderedList:
            return \.listBulleted
        case .orderedList:
            return \.listNumbered
        case .indent:
            return \.indentIncrease
        case .unindent:
            return \.indentDecrease
        case .inlineCode:
            return \.inlineCode
        case .codeBlock:
            return \.code
        case .quote:
            return \.quote
        case .link:
            return \.link
        }
    }

    var accessibilityIdentifier: String {
        switch type {
        case .bold:
            return A11yIdentifiers.roomScreen.composerToolbar.bold
        case .italic:
            return A11yIdentifiers.roomScreen.composerToolbar.italic
        case .underline:
            return A11yIdentifiers.roomScreen.composerToolbar.underline
        case .strikeThrough:
            return A11yIdentifiers.roomScreen.composerToolbar.strikethrough
        case .unorderedList:
            return A11yIdentifiers.roomScreen.composerToolbar.unorderedList
        case .orderedList:
            return A11yIdentifiers.roomScreen.composerToolbar.orderedList
        case .indent:
            return A11yIdentifiers.roomScreen.composerToolbar.indent
        case .unindent:
            return A11yIdentifiers.roomScreen.composerToolbar.unindent
        case .inlineCode:
            return A11yIdentifiers.roomScreen.composerToolbar.inlineCode
        case .codeBlock:
            return A11yIdentifiers.roomScreen.composerToolbar.codeBlock
        case .quote:
            return A11yIdentifiers.roomScreen.composerToolbar.quote
        case .link:
            return A11yIdentifiers.roomScreen.composerToolbar.link
        }
    }

    var accessibilityLabel: String {
        switch type {
        case .bold:
            return L10n.richTextEditorFormatBold
        case .italic:
            return L10n.richTextEditorFormatItalic
        case .underline:
            return L10n.richTextEditorFormatUnderline
        case .strikeThrough:
            return L10n.richTextEditorFormatStrikethrough
        case .unorderedList:
            return L10n.richTextEditorBulletList
        case .orderedList:
            return L10n.richTextEditorNumberedList
        case .indent:
            return L10n.richTextEditorIndent
        case .unindent:
            return L10n.richTextEditorUnindent
        case .inlineCode:
            return L10n.richTextEditorInlineCode
        case .codeBlock:
            return L10n.richTextEditorCodeBlock
        case .quote:
            return L10n.richTextEditorQuote
        case .link:
            return L10n.richTextEditorLink
        }
    }
}

extension FormatType {
    /// The associated library composer action.
    var composerAction: ComposerAction {
        switch self {
        case .bold:
            return .bold
        case .italic:
            return .italic
        case .underline:
            return .underline
        case .strikeThrough:
            return .strikeThrough
        case .unorderedList:
            return .unorderedList
        case .orderedList:
            return .orderedList
        case .indent:
            return .indent
        case .unindent:
            return .unindent
        case .inlineCode:
            return .inlineCode
        case .codeBlock:
            return .codeBlock
        case .quote:
            return .quote
        case .link:
            return .link
        }
    }
}
