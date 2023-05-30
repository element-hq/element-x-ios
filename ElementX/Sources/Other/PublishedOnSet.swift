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

/// Creates a property that provides a publisher via it's projected value. Similar to (ab)using `@Published` but
/// works outside of an `ObservableObject` and the publisher is fired on `didSet` instead of `willSet`.
@propertyWrapper struct PublishedOnSet<Value> {
    private let subject: PassthroughSubject<Value, Never> = .init()
    
    var wrappedValue: Value {
        didSet { subject.send(wrappedValue) }
    }
    
    var projectedValue: AnyPublisher<Value, Never> { subject.eraseToAnyPublisher() }
}
