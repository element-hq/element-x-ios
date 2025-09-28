// 
// Copyright 2025 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct SnapshotPrecisionPreferenceKey: PreferenceKey {
    static var defaultValue: Float = 1.0

    static func reduce(value: inout Float, nextValue: () -> Float) {
        value = nextValue()
    }
}

struct SnapshotPerceptualPrecisionPreferenceKey: PreferenceKey {
    static var defaultValue: Float = 0.98

    static func reduce(value: inout Float, nextValue: () -> Float) {
        value = nextValue()
    }
}

extension SwiftUI.View {
    /// Use this modifier when you want to apply snapshot-specific preferences,
    /// like delay and precision, to the view.
    /// These preferences can then be retrieved and used elsewhere in your view hierarchy.
    ///
    /// - Parameters:
    ///   - delay: The delay time in seconds that you want to set as a preference to the View.
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. 98-99% mimics the precision of the human eye.
    func snapshotPreferences(expect fulfillmentPublisher: (any Publisher<Bool, Never>)? = nil,
                             precision: Float = 1.0,
                             perceptualPrecision: Float = 0.98) -> some SwiftUI.View {
        preference(key: SnapshotPrecisionPreferenceKey.self, value: precision)
            .preference(key: SnapshotPerceptualPrecisionPreferenceKey.self, value: perceptualPrecision)
    }
}
