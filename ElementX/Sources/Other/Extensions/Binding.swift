//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension Binding {
    /// When a type that is wrapped by a binding returns optionals, when using if let
    /// you are not unwrapping the value but the binding itself, which will not actually
    /// remove the optional ? type and get the value inside. This function creates a way
    /// to handle this case, by generating a new binding from the `wrappedValue` when not `nil`
    /// and return instead nil if there `wrappedValue` is `nil`
    func unwrap<T>() -> Binding<T>? where Value == T? {
        guard let wrappedValue = wrappedValue else {
            return nil
        }
        return Binding<T>(get: { wrappedValue },
                          set: { self.wrappedValue = $0 })
    }
}
