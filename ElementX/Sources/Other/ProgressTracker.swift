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

final class ProgressTracker: NSObject, URLSessionTaskDelegate {
    private var progressObservation: NSKeyValueObservation?
    @Published private var progressFraction: Double

    var progressFractionPublisher: AnyPublisher<Double, Never> {
        $progressFraction
            .receive(on: RunLoop.main)
            .eraseToAnyPublisher()
    }

    init(initialValue: Double = 0.0) {
        progressFraction = initialValue
    }

    func urlSession(_ session: URLSession, didCreateTask task: URLSessionTask) {
        progressObservation = task.progress.observe(\.fractionCompleted) { [weak self] progress, _ in
            self?.progressFraction = progress.fractionCompleted
        }
    }
}
