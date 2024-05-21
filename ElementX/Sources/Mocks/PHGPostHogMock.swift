//
// Copyright 2024 New Vector Ltd
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
import PostHog

extension PHGPostHogMock {
    func configureMockBehavior() {
        // We don't need custom configuration anymore since update of the posthog SDK
        // Keeping boilerplate code in case needed later?
    }
}

class MockPostHogFactory: PostHogFactory {
    var mock: PHGPostHogProtocol!
    
    init(mock: PHGPostHogProtocol!) {
        self.mock = mock
    }
    
    func createPostHog(config: PostHogConfig) -> PHGPostHogProtocol {
        mock
    }
}
