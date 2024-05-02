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

// sourcery: AutoMockable
protocol PHGPostHogProtocol {
    var enabled: Bool { get }
    
    func enable()
    
    func disable()
    
    func reset()
    
    func capture(_ event: String, properties: [String: Any]?)
    
    func screen(_ screenTitle: String, properties: [String: Any]?)
}

protocol PostHogFactory {
    func createPostHog(config: PHGPostHogConfiguration) -> PHGPostHogProtocol
}

class DefaultPostHogFactory: PostHogFactory {
    func createPostHog(config: PHGPostHogConfiguration) -> PHGPostHogProtocol {
        PHGPostHog(configuration: config)
    }
}

extension PHGPostHog: PHGPostHogProtocol { }
