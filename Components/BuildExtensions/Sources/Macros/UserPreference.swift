//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

/// Exposes a value backed by keyed storage as a computed property, alongside a `<name>Publisher`
/// peer that emits the current value and every subsequent change.
///
/// The generated accessors read and write through the enclosing type's `store` (a
/// `UserDefaultsProtocol`); a `volatile` preference is instead held in memory and resets on launch.
///
/// When `key` is omitted the property's own name is used as the storage key. Provide an explicit
/// `key` whenever the storage key must differ from the property name (e.g. to keep matching a value
/// persisted under a legacy key).
///
/// A `reset<Name>()` method is also generated, which clears the stored value so it reverts to the
/// default. Non-volatile preferences also get a `<name>Key` property exposing the storage key.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro UserPreference<Value>(key: String? = nil, defaultValue: Value, volatile: Bool = false) =
    #externalMacro(module: "MacrosImplementation", type: "UserPreferenceMacro")

/// A variant for optional preferences that default to `nil`.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro UserPreference(key: String? = nil, volatile: Bool = false) =
    #externalMacro(module: "MacrosImplementation", type: "UserPreferenceMacro")

/// The storage key of a `@UserPreference`, distinct from `String` so that only a generated
/// `<name>Key` property can be passed where a preference key is expected.
public struct UserPreferenceKey: Sendable {
    public let rawValue: String
    
    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}
