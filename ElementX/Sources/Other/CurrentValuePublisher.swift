//
// Copyright 2023 New Vector Ltd
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
