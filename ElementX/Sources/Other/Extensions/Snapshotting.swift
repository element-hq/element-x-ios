//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

public struct SnapshotDelayPreferenceKey: PreferenceKey {
    public static var defaultValue: TimeInterval = 0.0

    public static func reduce(value: inout TimeInterval, nextValue: () -> TimeInterval) {
        value = nextValue()
    }
}

public struct SnapshotPrecisionPreferenceKey: PreferenceKey {
    public static var defaultValue: Float = 1.0

    public static func reduce(value: inout Float, nextValue: () -> Float) {
        value = nextValue()
    }
}

public struct SnapshotPerceptualPrecisionPreferenceKey: PreferenceKey {
    public static var defaultValue: Float = 1.0

    public static func reduce(value: inout Float, nextValue: () -> Float) {
        value = nextValue()
    }
}

public extension SwiftUI.View {
    /// Use this modifier when you want to apply snapshot-specific preferences,
    /// like delay and precision, to the view.
    /// These preferences can then be retrieved and used elsewhere in your view hierarchy.
    ///
    /// - Parameters:
    ///   - delay: The delay time in seconds that you want to set as a preference to the View.
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. 98-99% mimics the precision of the human eye.
    @inlinable
    func snapshotPreferences(delay: TimeInterval = .zero, precision: Float = 1.0, perceptualPrecision: Float = 1.0) -> some SwiftUI.View {
        preference(key: SnapshotDelayPreferenceKey.self, value: delay)
            .preference(key: SnapshotPrecisionPreferenceKey.self, value: precision)
            .preference(key: SnapshotPerceptualPrecisionPreferenceKey.self, value: perceptualPrecision)
    }
}
