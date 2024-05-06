//
// Copyright 2021 New Vector Ltd
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

import PostHog

extension PostHogConfig {
    static func standard(analyticsConfiguration: AnalyticsConfiguration) -> PostHogConfig? {
        guard analyticsConfiguration.isEnabled else { return nil }
        
        let postHogConfiguration = PostHogConfig(apiKey: analyticsConfiguration.apiKey, host: analyticsConfiguration.host)
        // We capture screens manually
        postHogConfiguration.captureScreenViews = false
        
        return postHogConfiguration
    }
}
