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

extension Sequence {
    func asyncMap<T>(_ transform: @escaping (Element) async -> T) async -> [T] {
        await withTaskGroup(of: T.self) { group in
            var transformedElements = [T]()

            for element in self {
                group.addTask {
                    await transform(element)
                }
            }

            for await transformedElement in group {
                transformedElements.append(transformedElement)
            }

            return transformedElements
        }
    }
}
