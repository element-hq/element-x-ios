//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

nonisolated enum TimelineEventContent: Hashable {
    case message(EventBasedMessageTimelineItemContentType)
    case poll(question: String)
    case liveLocation
    case redacted
}

nonisolated extension TimelineEventContent {
    /// A one-line, sender-free preview of the content for search result rows.
    /// `nil` for media content, which renders a media preview instead.
    var searchPreviewBody: AttributedString? {
        switch self {
        case .message(let content):
            switch content {
            case .text(let content):
                content.formattedBody ?? AttributedString(content.body)
            case .notice(let content):
                content.formattedBody ?? AttributedString(content.body)
            case .emote(let content):
                content.formattedBody ?? AttributedString(content.body)
            case .audio, .file, .image, .video, .gallery:
                nil
            case .voice:
                AttributedString(L10n.commonVoiceMessage)
            case .location:
                AttributedString(L10n.commonSharedLocation)
            }
        case .poll(let question):
            AttributedString(question)
        case .liveLocation:
            AttributedString(L10n.commonSharedLiveLocation)
        case .redacted:
            AttributedString(L10n.commonMessageRemoved)
        }
    }
}
