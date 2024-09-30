//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

extension Published.Publisher {
    /// Returns the next output from the publisher skipping the current value stored into it (which is readable from the @Published property itself).
    /// - Returns: the next output from the publisher
    var nextValue: Output? {
        get async {
            var iterator = values.makeAsyncIterator()
            
            // skips the publisher's current value
            _ = await iterator.next()
            return await iterator.next()
        }
    }
}
