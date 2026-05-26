//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// See ``LockBox`` - Mostly the same, but the value stored with `weak` reference semantics
@dynamicMemberLookup
final class WeakLockBox<Wrapped: AnyObject> {
    private let isolationLock = NSLock()
    
    private weak var _value: Wrapped?
    
    subscript<T: Sendable>(dynamicMember member: KeyPath<Wrapped, T>) -> T? {
        withLock {
            $0[keyPath: member]
        }
    }
    
    init(_ value: Wrapped) {
        self._value = value
    }
    
    /// See ``LockBox.withLock`` - Mostly the same, but since the `value` is stored weakly, this
    /// only executes if the pointer is not nil.
    func withLock<Success, Failure: Error>(_ block: (inout Wrapped) throws(Failure) -> sending Success?) throws(Failure) -> sending Success? {
        do {
            isolationLock.lock()
            defer { isolationLock.unlock() }
            guard var _value else { return nil }
            let output = try block(&_value)
            self._value = _value
            return output
        } catch {
            throw error
        }
    }
}

extension WeakLockBox: @unchecked Sendable where Wrapped: Sendable {
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
}
