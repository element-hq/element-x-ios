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
    
    func withLock<Success, Failure: Error>(_ block: (inout Wrapped) throws(Failure) -> Success?) throws(Failure) -> Success? {
        do {
            return try isolationLock.withLock {
                guard var _value else { return nil }
                let output = try block(&_value)
                self._value = _value
                return output
            }
        } catch let error as Failure {
            throw error
        } catch {
            // NSRecursiveLock rethrows instead of using typed throws, but `block` can only throw `Failure`
            fatalError("this path is impossible")
        }
    }
}

extension WeakLockBox: @unchecked Sendable where Wrapped: Sendable { }
