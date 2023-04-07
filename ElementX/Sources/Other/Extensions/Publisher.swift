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
import Foundation

extension Publisher where Self.Failure == Never {
    func weakAssign<Root: AnyObject>(to keyPath: ReferenceWritableKeyPath<Root, Self.Output>, on object: Root) -> AnyCancellable {
        sink { [weak object] value in
            object?[keyPath: keyPath] = value
        }
    }
}

extension Publisher where Output == String, Failure == Never {
    func delayTextOrImmediateClear() -> AnyPublisher<String, Never> {
        map { query in
            // debounce search queries but make sure clearing the search updates immediately
            let milliseconds = query.isEmpty ? 0 : 500
            return Just(query).delay(for: .milliseconds(milliseconds), scheduler: DispatchQueue.main)
        }
        .switchToLatest()
        .removeDuplicates()
        .eraseToAnyPublisher()
    }
}
