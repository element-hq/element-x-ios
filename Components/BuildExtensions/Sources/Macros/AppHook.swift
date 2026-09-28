//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

/// Exposes a `Mutex`-backed hook as a read-only computed property, alongside a `register<Name>`
/// peer that swaps in a replacement hook.
///
/// The `default` argument provides the hook used until (and unless) a replacement is registered.
/// The enclosing type must have `Synchronization` in scope for the generated `Mutex` storage.
@attached(accessor)
@attached(peer, names: arbitrary)
public macro AppHook<Value>(default: Value) =
    #externalMacro(module: "MacrosImplementation", type: "AppHookMacro")
