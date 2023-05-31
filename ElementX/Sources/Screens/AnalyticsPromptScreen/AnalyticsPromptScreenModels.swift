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

enum AnalyticsPromptScreenViewAction {
    /// Enable analytics.
    case enable
    /// Disable analytics.
    case disable
}

enum AnalyticsPromptScreenViewModelAction {
    /// Enable analytics.
    case enable
    /// Disable analytics.
    case disable
}

struct AnalyticsPromptScreenViewState: BindableState {
    /// Attributed strings created from localized HTML.
    let strings: AnalyticsPromptScreenStrings
}

/// A collection of strings for the UI that need to be parsed from HTML
struct AnalyticsPromptScreenStrings {
    let optInContent: AttributedString
    let point1 = AttributedStringBuilder().fromHTML(L10n.screenAnalyticsPromptDataUsage)?.replacingFontWithPresentationIntent() ?? AttributedString(L10n.screenAnalyticsPromptDataUsage)
    let point2 = AttributedStringBuilder().fromHTML(L10n.screenAnalyticsPromptThirdPartySharing)?.replacingFontWithPresentationIntent() ?? AttributedString(L10n.screenAnalyticsPromptThirdPartySharing)
    let point3 = L10n.screenAnalyticsPromptSettings
    
    init(termsURL: URL) {
        let content = AttributedString(L10n.screenAnalyticsPromptHelpUsImprove(InfoPlistReader.main.bundleDisplayName))
        // Create the opt in content with a placeholder.
        let linkPlaceholder = "{link}"
        var readTerms = AttributedString(L10n.screenAnalyticsPromptReadTerms(linkPlaceholder))
        readTerms.replace(linkPlaceholder,
                          with: L10n.screenAnalyticsPromptReadTermsContentLink,
                          asLinkTo: termsURL)
        optInContent = content + "\n\n" + readTerms
    }
}
