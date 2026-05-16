//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Wraps a non-Sendable type and assures most of its interactions are done in isolation with locking mechanisms
///
/// The exception is reference types. If multiple SendableBox instances are created with a reference to the same class,
/// each SendableBox operates in isolation and ignorance of the others. When using with reference types (or value
/// types that point to reference types), make sure to only create one Box instance per instance of Wrapped.
///
/// Leverages the `@dynamicMemberLookup` feature in swift to be able to access properties directly on the Box.
@Observable
@dynamicMemberLookup
final class SendableBox<Wrapped>: @unchecked Sendable {
    private let isolationLock = NSRecursiveLock()
    
    private var _value: Wrapped
    var value: Wrapped {
        get { isolationLock.withLock { _value } }
        set { isolationLock.withLock { _value = newValue } }
    }
    
    subscript<T>(dynamicMember member: WritableKeyPath<Wrapped, T>) -> T {
        get { value[keyPath: member] }
        set { value[keyPath: member] = newValue }
    }
    
    subscript<T>(dynamicMember member: KeyPath<Wrapped, T>) -> T {
        value[keyPath: member]
    }
    
    init(_ value: Wrapped) {
        self._value = value
    }
}

extension SendableBox: ExpressibleByNilLiteral where Wrapped: ExpressibleByNilLiteral {
    convenience init(nilLiteral: ()) {
        self.init(nil)
    }
}
