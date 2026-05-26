//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

extension View {
    /// Reads the frame of the view and stores it in the `frame` binding.
    /// - Parameters:
    ///   - frame: a `CGRect` binding
    func readFrame(_ frame: Binding<CGRect>) -> some View {
        onGeometryChange(for: CGRect.self) { geometry in
            geometry.frame(in: .local)
        } action: { newValue in
            if frame.wrappedValue != newValue {
                frame.wrappedValue = newValue
            }
        }
    }
    
    /// Reads the height of the view and stores it in the `height` binding.
    /// - Parameters:
    ///   - height: a `CGFloat` binding
    func readHeight(_ height: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
        } action: { newValue in
            if height.wrappedValue != newValue {
                height.wrappedValue = newValue
            }
        }
    }
    
    /// Reads the width of the view and stores it in the `width` binding.
    /// - Parameters:
    ///   - width: a `CGFloat` binding
    func readWidth(_ width: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.width
        } action: { newValue in
            if width.wrappedValue != newValue {
                width.wrappedValue = newValue
            }
        }
    }
}
