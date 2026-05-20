//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Synchronizes access to a stored value across concurrency boundaries by protecting it with a lock, enabling
/// `Sendable` conformance on the containing type.
///
/// This addresses one specific concern: the container's unsynchronized hold on its stored property. It does not
/// address the internal thread-safety of the wrapped value itself -- that remains a separate responsibility. For
/// reference types, this means the box synchronizes the pointer, not the internals of the referenced object. This
/// is intentional and consistent with how other synchronization primitives work.
///
/// **Important:** `box.value.doThing()` retrieves the value under the lock but executes `doThing()` outside it.
/// When the operation itself must be atomic with the lock, use `withLock { }` instead.
///
/// **Disciplines required:**
/// - For reference types: the wrapped type should itself be `Sendable`, or internal mutations must be
/// otherwise synchronized
/// - Only one `LockBox` instance should exist per instance of a wrapped reference type (multiple boxes
///  do not synchronize with each other)
/// - Mutations to the wrapped value should go through the box, not via a retained reference to the wrapped object
/// - For reference types, use `withLock { }` when the operation on the referenced object must be atomic with
///   the pointer read
///
/// **Benefits attained:**
/// - Access to the stored property (pointer/reference for reference types) is synchronized -- no unsynchronized
///   reassignment of the stored property can occur
/// - When used as a property on a container, each wrapped property carries its own synchronized conformance,
/// reducing the need for broad `@unchecked Sendable` on the containing type
///
/// Leverages `@dynamicMemberLookup` for ergonomic property access directly on the box.
@Observable
@dynamicMemberLookup
final class LockBox<Wrapped> {
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
    
    func withLock<Success, Failure: Error>(_ block: (inout Wrapped) throws(Failure) -> Success) throws(Failure) -> Success {
        do {
            return try isolationLock.withLock {
                try block(&_value)
            }
        } catch let error as Failure {
            throw error
        } catch {
            // NSRecursiveLock rethrows instead of using typed throws, but `block` can only throw `Failure`
            fatalError("this path is impossible")
        }
    }
}

extension LockBox: ExpressibleByNilLiteral where Wrapped: ExpressibleByNilLiteral {
    convenience init(nilLiteral: ()) {
        self.init(nil)
    }
}

extension LockBox: @unchecked Sendable where Wrapped: Sendable { }
