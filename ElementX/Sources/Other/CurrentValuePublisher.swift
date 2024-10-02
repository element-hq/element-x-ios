//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine

/// A wrapper of CurrentValueSubject.
/// The purpose of this type is to remove the possibility to send new values on the underlying subject.
struct CurrentValuePublisher<Output, Failure: Error>: Publisher {
    private let subject: CurrentValueSubject<Output, Failure>
    
    init(_ subject: CurrentValueSubject<Output, Failure>) {
        self.subject = subject
    }
    
    init(_ value: Output) {
        self.init(CurrentValueSubject(value))
    }
    
    func receive<S>(subscriber: S) where S: Subscriber, Failure == S.Failure, Output == S.Input {
        subject.receive(subscriber: subscriber)
    }
    
    var value: Output {
        subject.value
    }
}

extension CurrentValueSubject {
    func asCurrentValuePublisher() -> CurrentValuePublisher<Output, Failure> {
        .init(self)
    }
}
