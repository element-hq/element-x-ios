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
import UIKit
import WysiwygComposer

enum ComposerToolbarViewModelAction {
    case sendMessage(plain: String, html: String?, mode: RoomScreenComposerMode)
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker
    case displayPollForm

    case handlePasteOrDrop(provider: NSItemProvider)

    case composerModeChanged(mode: RoomScreenComposerMode)
    case composerFocusedChanged(isFocused: Bool)
}

enum ComposerToolbarViewAction {
    case composerAppeared
    case sendMessage
    case cancelReply
    case cancelEdit
    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker
    case displayPollForm
    case handlePasteOrDrop(provider: NSItemProvider)
    case enableTextFormatting
    case composerAction(action: ComposerAction)
}

struct ComposerToolbarViewState: BindableState {
    var composerMode: RoomScreenComposerMode = .default
    var composerEmpty = true
    var areSuggestionsEnabled = true

    var bindings: ComposerToolbarViewStateBindings

    var sendButtonDisabled: Bool {
        composerEmpty
    }
}

struct ComposerToolbarViewStateBindings {
    var composerFocused = false
    var composerActionsEnabled = false
    var composerExpanded = false
    var formatItems: [FormatItem] = .init()
    var alertInfo: AlertInfo<UUID>?

    var showAttachmentPopover = false {
        didSet {
            if showAttachmentPopover {
                composerFocused = false
            }
        }
    }
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
    var icon: Image {
        switch type {
        case .bold:
            return Image(asset: Asset.Images.bold)
        case .italic:
            return Image(asset: Asset.Images.italic)
        case .underline:
            return Image(asset: Asset.Images.underline)
        case .strikeThrough:
            return Image(asset: Asset.Images.strikethrough)
        case .unorderedList:
            return Image(asset: Asset.Images.bulletList)
        case .orderedList:
            return Image(asset: Asset.Images.numberedList)
        case .indent:
            return Image(asset: Asset.Images.indent)
        case .unindent:
            return Image(asset: Asset.Images.unindent)
        case .inlineCode:
            return Image(asset: Asset.Images.inlineCode)
        case .codeBlock:
            return Image(asset: Asset.Images.codeBlock)
        case .quote:
            return Image(asset: Asset.Images.quote)
        case .link:
            return Image(asset: Asset.Images.link)
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
