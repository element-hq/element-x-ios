//
// Copyright 2022 New Vector Ltd
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

/// A type that represents how to set up the analytics module in the app.
struct AnalyticsConfiguration {
    /// Whether or not analytics should be enabled.
    let isEnabled: Bool
    /// The host to use for PostHog analytics.
    let host: String
    /// The public key for submitting analytics.
    let apiKey: String
    /// The URL to open with more information about analytics terms.
    let termsURL: URL
}
