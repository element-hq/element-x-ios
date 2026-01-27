//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

/// A setting that can be instantiated with a default value, remotely overridden and reset back
/// to the default, automatically publishing the changes for downstream subscribers to react to.
///
/// Unlike ``UserPreference``, this type of setting isn't settable by the user, nor is the
/// remote value persisted between app launches.
class RemotePreference<T: Equatable> {
    private let defaultValue: T
    private let subject: CurrentValueSubject<T, Never>
    var publisher: CurrentValuePublisher<T, Never> {
        subject.asCurrentValuePublisher()
    }

    var isRemotelyConfigured: Bool {
        subject.value != defaultValue
    }
    
    init(_ defaultValue: T) {
        self.defaultValue = defaultValue
        subject = .init(defaultValue)
    }
    
    func applyRemoteValue(_ value: T) {
        subject.send(value)
    }
    
    func reset() {
        if isRemotelyConfigured {
            subject.send(defaultValue)
        }
    }
}
