//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine

/// A setting that can be instantiated with an initial value, overridden and reset back again,
/// automatically publishing the changes for downstream subscribers to react to.
///
/// Unlike ``UserPreference``, this type of setting isn't settable by the user, nor is the
/// override persisted between app launches.
struct ConfigurableSetting<T: Equatable> {
    private let initialValue: T
    private let subject: CurrentValueSubject<T, Never>
    var publisher: CurrentValuePublisher<T, Never> { subject.asCurrentValuePublisher() }
    var isOverridden: Bool { subject.value != initialValue }
    
    init(_ initialValue: T) {
        self.initialValue = initialValue
        subject = .init(initialValue)
    }
    
    func override(_ value: T) {
        subject.send(value)
    }
    
    func reset() {
        if isOverridden {
            subject.send(initialValue)
        }
    }
}
