//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension Dictionary {
    var jsonString: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self,
                                                     options: [.fragmentsAllowed, .sortedKeys]) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
    
    /// Returns a dictionary containing the original values keyed by the results of mapping the given closure over its keys.
    func mapKeys<T>(_ transform: (Key) -> T) -> [T: Value] {
        .init(map { (transform($0.key), $0.value) }) { first, _ in first }
    }
}
