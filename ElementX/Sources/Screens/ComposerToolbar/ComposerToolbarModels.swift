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

import UIKit

enum ComposerToolbarViewModelAction {
    case sendMessage(message: String, mode: RoomScreenComposerMode)

    case displayCameraPicker
    case displayMediaPicker
    case displayDocumentPicker
    case displayLocationPicker

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
    case handlePasteOrDrop(provider: NSItemProvider)
}

struct ComposerToolbarViewState: BindableState {
    var composerMode: RoomScreenComposerMode = .default
    var composerEmpty = true

    var bindings: ComposerToolbarViewStateBindings

    var sendButtonDisabled: Bool {
        composerEmpty
    }
}

struct ComposerToolbarViewStateBindings {
    var composerFocused: Bool

    var showAttachmentPopover = false {
        didSet {
            if showAttachmentPopover {
                composerFocused = false
            }
        }
    }
}
