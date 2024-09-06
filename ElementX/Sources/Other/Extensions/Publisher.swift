//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

extension Publisher where Self.Failure == Never {
    func weakAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}

extension Publisher where Output: Equatable, Failure == Never {
    func debounceAndRemoveDuplicates<S: Scheduler>(on scheduler: S, delay: @escaping (Output) -> S.SchedulerTimeType.Stride) -> AnyPublisher<Output, Never> {
        map { query in
            Just(query).delay(for: delay(query), scheduler: scheduler)
        }
        .switchToLatest()
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}

extension Publisher where Output == String, Failure == Never {
    /// Debounce text queries and remove duplicates.
    /// Clearing the text publishes the update immediately.
    func debounceTextQueriesAndRemoveDuplicates() -> AnyPublisher<String, Never> {
        debounceAndRemoveDuplicates(on: DispatchQueue.main) { query in
            query.isEmpty ? .milliseconds(0) : .milliseconds(250)
        }
    }
}
