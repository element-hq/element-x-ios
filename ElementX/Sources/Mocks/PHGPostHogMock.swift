//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
