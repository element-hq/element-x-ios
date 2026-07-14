//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

/// A wrapper of CurrentValueSubject.
/// The purpose of this type is to remove the possibility to send new values on the underlying subject.
///
/// `CurrentValueSubject` is documented as thread-safe but is not formally `Sendable`, hence `@unchecked`.
nonisolated struct CurrentValuePublisher<Output, Failure: Error>: Publisher, @unchecked Sendable {
    private let upstream: AnyPublisher<Output, Failure>
    private let valueProvider: () -> Output
    
    init(_ subject: CurrentValueSubject<Output, Failure>) {
        upstream = subject.eraseToAnyPublisher()
        valueProvider = { subject.value }
    }
    
    init(_ value: Output) {
        self.init(CurrentValueSubject(value))
    }
    
    private init(upstream: AnyPublisher<Output, Failure>, valueProvider: @escaping () -> Output) {
        self.upstream = upstream
        self.valueProvider = valueProvider
    }
    
    func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        upstream.receive(subscriber: subscriber)
    }
    
    var value: Output {
        valueProvider()
    }
}

nonisolated extension CurrentValuePublisher where Failure == Never {
    /// Transform the published values (and ``value``), subscribing to the underlying subject
    /// lazily, per subscriber.
    ///
    /// Bridging eagerly through a second subject doesn't work here: the subscription feeding it
    /// would need to be retained by this struct, but Combine consumes publisher structs when
    /// building a subscription, so chaining a mapped publisher inline dropped the feed and
    /// downstream only ever received the initial value (e.g. the knock requests banner never
    /// updated for a knock arriving while the room was open).
    func map<T>(_ transform: @escaping (Output) -> T) -> CurrentValuePublisher<T, Never> {
        .init(upstream: upstream.map(transform).eraseToAnyPublisher(),
              valueProvider: { transform(value) })
    }
}

nonisolated extension CurrentValueSubject {
    func asCurrentValuePublisher() -> CurrentValuePublisher<Output, Failure> {
        .init(self)
    }
}
