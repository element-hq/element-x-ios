//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Synchronizes access to a stored value across concurrency boundaries by protecting it with a lock.
///
/// This addresses one specific concern: the container's unsynchronized hold on its stored property. It does not
/// address the internal thread-safety of the wrapped value itself -- that remains a separate responsibility. For
/// reference types, this means the box synchronizes the pointer, not the internals of the referenced object. This
/// is intentional and consistent with how other synchronization primitives work.
///
/// **API availability is tiered by `Wrapped`'s `Sendable` conformance:**
/// - For any `Wrapped`: individual `Sendable` properties are readable via `@dynamicMemberLookup`,
/// and `withLock { }` is available for full access
/// - When `Wrapped: Sendable`: `.value`, mutable property access, and `Sendable` conformance
/// on the box itself are additionally available
///
/// This means a non-`Sendable` wrapped type cannot be escaped from the box or mutated through it
/// without going through `withLock { }` -- the same discipline `Mutex` requires, with the addition
/// that mutation is compiler-enforced rather than API-enforced.
///
/// **Important:** `box.value.doThing()` retrieves the value under the lock but executes `doThing()`
/// outside it, relying on `Wrapped`'s `Sendable` conformance for safety. When the operation itself must be
/// atomic with the lock, use `withLock { }` instead.
///
/// **Disciplines required:**
/// - For reference types, use `withLock { }` when the operation on the referenced object must be atomic with
/// the pointer read
///
/// **Benefits attained:**
/// - Access to the stored property (pointer/reference for reference types) is synchronized -- no unsynchronized
/// reassignment can occur
/// - Each wrapped property carries its own synchronized conformance, reducing the need for broad `@unchecked Sendable`
/// on the containing type
///
/// Leverages `@dynamicMemberLookup` for ergonomic property access directly on the box.
@Observable
@dynamicMemberLookup
final class LockBox<Wrapped> {
    private let isolationLock = NSRecursiveLock()
    
    private var _value: Wrapped
    
    subscript<T: Sendable>(dynamicMember member: KeyPath<Wrapped, T>) -> T {
        withLock {
            $0[keyPath: member]
        }
    }
    
    init(_ value: Wrapped) {
        self._value = value
    }
    
    /// Executes `block` with exclusive access to the wrapped value.
    ///
    /// Use this instead of `value` when:
    /// - The operation on a referenced object must be atomic with the pointer read -- i.e. the reference should
    /// not be able to change between reading it and acting on it. This is the typical use case for
    /// wrapped reference types:
    ///
    ///     ```swift
    ///     // Not atomic -- reference could be replaced between read and method call
    ///     box.value?.doThing()
    ///
    ///     // Atomic -- pointer read and method call are a single unit
    ///     box.withLock { value in
    ///         value?.doThing()
    ///     }
    ///     ```
    ///
    /// - A compound operation (read + modify, or multiple mutations) must execute as an uninterruptible unit,
    /// preventing other threads from observing intermediate state. This is more typical for wrapped value
    /// types, though neither use case is exclusive to one or the other:
    ///
    ///     ```swift
    ///     // Not atomic -- another thread could modify value between the read and write
    ///     let current = box.value
    ///     box.value = transform(current)
    ///
    ///     // Atomic -- the entire operation is a single unit
    ///     box.withLock { value in
    ///         value = transform(value)
    ///     }
    ///     ```
    func withLock<Success, Failure: Error>(_ block: (inout Wrapped) throws(Failure) -> sending Success) throws(Failure) -> sending Success {
        isolationLock.lock()
        defer { isolationLock.unlock() }
        do throws(Failure) {
            return try block(&_value)
        } catch {
            throw error
        }
    }
}

extension LockBox: ExpressibleByNilLiteral where Wrapped: ExpressibleByNilLiteral {
    convenience init(nilLiteral: ()) {
        self.init(nil)
    }
}

extension LockBox: ExpressibleByBooleanLiteral where Wrapped: ExpressibleByBooleanLiteral {
    convenience init(booleanLiteral value: Wrapped.BooleanLiteralType) {
        self.init(Wrapped(booleanLiteral: value))
    }
}

extension LockBox: @unchecked Sendable where Wrapped: Sendable {
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
}
