//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

extension AsyncSequence {
    func first() async rethrows -> Self.Element? {
        try await first { _ in true }
    }
    
    /// Type-erases the sequence into a newly constructed asynchronous stream. This is useful until
    /// we drop support for iOS 17, at which point we can replace this with `any AsyncSequence`.
    @available(iOS, deprecated: 18.0, message: "Use `any AsyncSequence` instead.")
    func eraseToStream() -> AsyncStream<Element> {
        var asyncIterator = makeAsyncIterator()
        return AsyncStream<Element> {
            do {
                return try await asyncIterator.next()
            } catch {
                MXLog.warning("Stopping stream: \(error)")
                return nil
            }
        }
    }
}
