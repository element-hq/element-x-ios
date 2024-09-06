//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import PostHog

// sourcery: AutoMockable
protocol PHGPostHogProtocol {
    func optIn()
    
    func optOut()
    
    func reset()
    
    func capture(_ event: String, properties: [String: Any]?, userProperties: [String: Any]?)
    
    func screen(_ screenTitle: String, properties: [String: Any]?)
}

protocol PostHogFactory {
    func createPostHog(config: PostHogConfig) -> PHGPostHogProtocol
}

class DefaultPostHogFactory: PostHogFactory {
    func createPostHog(config: PostHogConfig) -> PHGPostHogProtocol {
        PostHogSDK.shared.setup(config)
        return PostHogSDK.shared
    }
}

extension PostHogSDK: PHGPostHogProtocol { }
