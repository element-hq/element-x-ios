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

struct FulfillmentPublisherEquatableWrapper: Equatable {
    let publisher: AnyPublisher<Bool, Never>?
    
    // Publisher equatability complicates things but, luckily, we're only interesting in them changing from nil
    static func == (lhs: FulfillmentPublisherEquatableWrapper, rhs: FulfillmentPublisherEquatableWrapper) -> Bool {
        lhs.publisher != nil && rhs.publisher != nil
    }
}

struct SnapshotFulfillmentPublisherPreferenceKey: PreferenceKey {
    static var defaultValue: FulfillmentPublisherEquatableWrapper?

    static func reduce(value: inout FulfillmentPublisherEquatableWrapper?, nextValue: () -> FulfillmentPublisherEquatableWrapper?) {
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
            .preference(key: SnapshotFulfillmentPublisherPreferenceKey.self, value: FulfillmentPublisherEquatableWrapper(publisher: fulfillmentPublisher?.eraseToAnyPublisher()))
    }
}
