//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The reported background drawn by a view.
public enum CompoundBackground: Equatable {
    /// A specific background colour.
    case color(Color)
    /// The default canvas background.
    case `default`
    
    public var colorValue: Color {
        switch self {
        case .color(let color): color
        case .default: .compound.bgCanvasDefault
        }
    }
}

/// A background reported up the hierarchy by a view that opts in, so that surrounding chrome (e.g. the
/// tab rail that sits alongside iOS 26's inset sidebar) can match that view's canvas.
public struct CompoundBackgroundPreferenceKey: PreferenceKey {
    public static let defaultValue: CompoundBackground? = nil
    
    public static func reduce(value: inout CompoundBackground?, nextValue: () -> CompoundBackground?) {
        if let nextValue = nextValue() {
            value = nextValue
        }
    }
}
