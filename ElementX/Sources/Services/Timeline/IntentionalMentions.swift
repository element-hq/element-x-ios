//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

import MatrixRustSDK
import WysiwygComposer

struct IntentionalMentions: Equatable {
    let userIDs: Set<String>
    let atRoom: Bool
}

extension IntentionalMentions {
    static var empty: Self {
        IntentionalMentions(userIDs: .init(), atRoom: false)
    }
    
    func toRustMentions() -> Mentions {
        Mentions(userIds: Array(userIDs), room: atRoom)
    }
}

extension MentionsState {
    func toIntentionalMentions() -> IntentionalMentions {
        IntentionalMentions(userIDs: Set(userIds), atRoom: hasAtRoomMention)
    }
}
