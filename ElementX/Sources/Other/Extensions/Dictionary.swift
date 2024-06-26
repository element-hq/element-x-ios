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

import Foundation

extension Dictionary {
    var jsonString: String? {
        guard let data = try? JSONSerialization.data(withJSONObject: self,
                                                     options: [.fragmentsAllowed, .sortedKeys]) else {
            return nil
        }
        return String(decoding: data, as: UTF8.self)
    }
    
    /// Returns a dictionary containing the original values keyed by the results of mapping the given closure over its keys.
    func mapKeys<T>(_ transform: (Key) -> T) -> [T: Value] {
        .init(map { (transform($0.key), $0.value) }) { first, _ in first }
    }
}
