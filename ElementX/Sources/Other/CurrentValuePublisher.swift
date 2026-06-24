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
    private let subject: CurrentValueSubject<Output, Failure>
    /// Retains the upstream subscription feeding ``subject`` when this publisher is derived via ``map(_:)``.
    private let cancellable: AnyCancellable?
    
    init(_ subject: CurrentValueSubject<Output, Failure>, cancellable: AnyCancellable? = nil) {
        self.subject = subject
        self.cancellable = cancellable
    }
    
    init(_ value: Output) {
        self.init(CurrentValueSubject(value))
    }
    
    func receive<S: Subscriber>(subscriber: S) where Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
    
    var value: Output {
        subject.value
    }
}

nonisolated extension CurrentValuePublisher where Failure == Never {
    func map<T>(_ transform: @escaping (Output) -> T) -> CurrentValuePublisher<T, Never> {
        let subject = CurrentValueSubject<T, Never>(transform(value))
        let cancellable = sink { subject.send(transform($0)) }
        return .init(subject, cancellable: cancellable)
    }
}

nonisolated extension CurrentValueSubject {
    func asCurrentValuePublisher() -> CurrentValuePublisher<Output, Failure> {
        .init(self)
    }
}
