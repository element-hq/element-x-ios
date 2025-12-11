//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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

struct SnapshotFulfillmentPreferenceKey: PreferenceKey {
    static var defaultValue: Wrapper?

    static func reduce(value: inout Wrapper?, nextValue: () -> Wrapper?) {
        value = nextValue()
    }
    
    enum Source {
        case publisher(AnyPublisher<Bool, Never>)
        case sequence(any AsyncSequence<Bool, Never>)
    }
    
    struct Wrapper: Equatable {
        let id = UUID()
        let source: Source
        
        static func == (lhs: Wrapper, rhs: Wrapper) -> Bool {
            lhs.id == rhs.id // Not ideal, but it's good enough for snapshots.
        }
    }
}

extension SwiftUI.View {
    /// Use this modifier when you want to apply snapshot-specific preferences,
    /// like delay and precision, to the view.
    /// These preferences can then be retrieved and used elsewhere in your view hierarchy.
    ///
    /// - Parameters:
    ///   - expect: A publisher that indicates when the preview is ready for snapshotting.
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. 98-99% mimics the precision of the human eye.
    func snapshotPreferences(expect fulfillmentPublisher: (any Publisher<Bool, Never>)? = nil,
                             precision: Float = 1.0,
                             perceptualPrecision: Float = 0.98) -> some SwiftUI.View {
        preference(key: SnapshotPrecisionPreferenceKey.self, value: precision)
            .preference(key: SnapshotPerceptualPrecisionPreferenceKey.self, value: perceptualPrecision)
            .preference(key: SnapshotFulfillmentPreferenceKey.self, value: fulfillmentPublisher.map { SnapshotFulfillmentPreferenceKey.Wrapper(source: .publisher($0.eraseToAnyPublisher())) })
    }
    
    /// Use this modifier when you want to apply snapshot-specific preferences,
    /// like delay and precision, to the view.
    /// These preferences can then be retrieved and used elsewhere in your view hierarchy.
    ///
    /// - Parameters:
    ///   - expect: An async sequence that indicates when the preview is ready for snapshotting.
    ///   - precision: The percentage of pixels that must match.
    ///   - perceptualPrecision: The percentage a pixel must match the source pixel to be considered a match. 98-99% mimics the precision of the human eye.
    func snapshotPreferences(expect fulfillmentSequence: (any AsyncSequence<Bool, Never>)? = nil,
                             precision: Float = 1.0,
                             perceptualPrecision: Float = 0.98) -> some SwiftUI.View {
        preference(key: SnapshotPrecisionPreferenceKey.self, value: precision)
            .preference(key: SnapshotPerceptualPrecisionPreferenceKey.self, value: perceptualPrecision)
            .preference(key: SnapshotFulfillmentPreferenceKey.self, value: fulfillmentSequence.map { SnapshotFulfillmentPreferenceKey.Wrapper(source: .sequence($0)) })
    }
}
