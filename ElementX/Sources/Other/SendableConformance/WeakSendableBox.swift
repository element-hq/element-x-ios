//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// See ``SendableBox`` - Mostly the same, but the value stored with `weak` reference semantics
@dynamicMemberLookup
final class WeakSendableBox<Wrapped: AnyObject>: @unchecked Sendable {
    private let isolationLock = NSRecursiveLock()
    
    private weak var _value: Wrapped?
    var value: Wrapped? {
        get { isolationLock.withLock { _value } }
        set { isolationLock.withLock { _value = newValue } }
    }
    
    subscript<T>(dynamicMember member: WritableKeyPath<Wrapped, T?>) -> T? {
        get { value?[keyPath: member] }
        set { value?[keyPath: member] = newValue }
    }
    
    subscript<T>(dynamicMember member: KeyPath<Wrapped, T>) -> T? {
        value?[keyPath: member]
    }
    
    init(_ value: Wrapped) {
        self._value = value
    }
}
