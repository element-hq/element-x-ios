//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

// MARK: Redact message content from logs

extension EmoteMessageContent: @retroactive CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension FileMessageContent: @retroactive CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension ImageMessageContent: @retroactive CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension NoticeMessageContent: @retroactive CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension TextMessageContent: @retroactive CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension VideoMessageContent: @retroactive CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension AudioMessageContent: @retroactive CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}
