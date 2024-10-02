//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

@propertyWrapper struct Consumable<Value> {
    var wrappedValue: Value? {
        mutating get {
            defer {
                value = nil
            }
            return value
        }
        set {
            value = newValue
        }
    }

    private var value: Value?

    init(value: Value? = nil) {
        self.value = value
    }
}
