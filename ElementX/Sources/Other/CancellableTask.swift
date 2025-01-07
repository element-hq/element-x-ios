//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// periphery:ignore - property wrappers generate false positives
@propertyWrapper
struct CancellableTask<S: Sendable, F: Error> {
    private var storedValue: Task<S, F>?
    
    init(_ value: Task<S, F>? = nil) {
        storedValue = value
    }
    
    var wrappedValue: Task<S, F>? {
        get {
            storedValue
        } set {
            storedValue?.cancel()
            storedValue = newValue
        }
    }
}
