//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

extension Dictionary {
    var jsonString: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self,
                                                     options: [.fragmentsAllowed, .sortedKeys]) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }
    
    /// Returns a dictionary containing the original values keyed by the results of mapping the given closure over its keys.
    func mapKeys<T>(_ transform: (Key) -> T) -> [T: Value] {
        .init(map { (transform($0.key), $0.value) }) { first, _ in first }
    }
}
