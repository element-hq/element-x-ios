//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

extension View {
    /// Reads the frame of the view and store it in `frame` binding.
    /// - Parameters:
    ///   - frame: a `CGRect` binding
    ///   - coordinateSpace: the coordinate space of the frame.
    func readFrame(_ frame: Binding<CGRect>, in coordinateSpace: CoordinateSpace = .local) -> some View {
        background(ViewFrameReader(frame: frame, coordinateSpace: coordinateSpace))
    }
}

/// Used to calculate the frame of a view.
///
/// Useful in situations as with `ZStack` where you might want to layout views using alignment guides.
/// ```
/// @State private var frame: CGRect = CGRect.zero
/// ...
/// SomeView()
///    .background(ViewFrameReader(frame: $frame))
/// ```
private struct ViewFrameReader: View {
    @Binding var frame: CGRect
    var coordinateSpace: CoordinateSpace = .local
    
    var body: some View {
        GeometryReader { geometry in
            Color.clear
                .preference(key: FramePreferenceKey.self,
                            value: geometry.frame(in: coordinateSpace))
        }
        .onPreferenceChange(FramePreferenceKey.self) { newValue in
            guard frame != newValue else { return }
            frame = newValue
        }
    }
}

/// A SwiftUI `PreferenceKey` for `CGRect` values such as a view's frame.
private struct FramePreferenceKey: PreferenceKey {
    static var defaultValue: CGRect = .zero
    
    static func reduce(value: inout CGRect, nextValue: () -> CGRect) {
        value = nextValue()
    }
}
