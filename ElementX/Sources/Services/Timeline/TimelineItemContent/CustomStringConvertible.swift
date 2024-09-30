//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import MatrixRustSDK

// MARK: Redact message content from logs

extension EmoteMessageContent: CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension FileMessageContent: CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension ImageMessageContent: CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension NoticeMessageContent: CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension TextMessageContent: CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension VideoMessageContent: CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}

extension AudioMessageContent: CustomStringConvertible {
    public var description: String {
        String(describing: Self.self)
    }
}
