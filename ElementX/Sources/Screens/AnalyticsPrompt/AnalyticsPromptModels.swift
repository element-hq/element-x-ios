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

import Foundation

enum AnalyticsPromptViewAction {
    /// Enable analytics.
    case enable
    /// Disable analytics.
    case disable
}

enum AnalyticsPromptViewModelAction {
    /// Enable analytics.
    case enable
    /// Disable analytics.
    case disable
}

struct AnalyticsPromptViewState: BindableState {
    /// Attributed strings created from localized HTML.
    let strings = AnalyticsPromptStrings()
}

/// A collection of strings for the UI that need to be parsed from HTML
struct AnalyticsPromptStrings {
    let optInContent: AttributedString
    let point1 = AttributedStringBuilder().fromHTML(UntranslatedL10n.analyticsOptInListItem1) ?? AttributedString(UntranslatedL10n.analyticsOptInListItem1)
    let point2 = AttributedStringBuilder().fromHTML(UntranslatedL10n.analyticsOptInListItem2) ?? AttributedString(UntranslatedL10n.analyticsOptInListItem2)
    
    init() {
        // Create the opt in content with a placeholder.
        let linkPlaceholder = "{link}"
        var optInContent = AttributedString(UntranslatedL10n.analyticsOptInContent(InfoPlistReader.main.bundleDisplayName, linkPlaceholder))
        optInContent.replace(linkPlaceholder,
                             with: UntranslatedL10n.analyticsOptInContentLink,
                             asLinkTo: ServiceLocator.shared.settings.analyticsConfiguration.termsURL)
        self.optInContent = optInContent
    }
}
