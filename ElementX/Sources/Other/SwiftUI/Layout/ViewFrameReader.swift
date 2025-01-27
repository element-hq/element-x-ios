//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import SwiftUI

extension View {
    /// Reads the frame of the view and stores it in the `frame` binding.
    /// - Parameters:
    ///   - frame: a `CGRect` binding
    ///   - coordinateSpace: the coordinate space of the frame.
    func readFrame(_ frame: Binding<CGRect>, in coordinateSpace: CoordinateSpace = .local) -> some View {
        onGeometryChange(for: CGRect.self) { geometry in
            geometry.frame(in: coordinateSpace)
        } action: { newValue in
            frame.wrappedValue = newValue
        }
    }
    
    /// Reads the height of the view and stores it in the `height` binding.
    /// - Parameters:
    ///   - height: a `CGFloat` binding
    func readHeight(_ height: Binding<CGFloat>) -> some View {
        onGeometryChange(for: CGFloat.self) { geometry in
            geometry.size.height
        } action: { newValue in
            height.wrappedValue = newValue
        }
    }
}
