//
// Copyright 2021-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    let point1 = L10n.screenAnalyticsPromptDataUsage
    let point2 = L10n.screenAnalyticsPromptThirdPartySharing
    let point3 = L10n.screenAnalyticsPromptSettings
    
    init(termsURL: URL) {
        let content = AttributedString(L10n.screenAnalyticsPromptHelpUsImprove)
        
        // Create the 'read terms' with a placeholder.
        let linkPlaceholder = "{link}"
        var readTerms = AttributedString(L10n.screenAnalyticsSettingsReadTerms(linkPlaceholder))
        var linkString = AttributedString(L10n.screenAnalyticsSettingsReadTermsContentLink)
        linkString.link = termsURL
        linkString.bold()
        readTerms.replace(linkPlaceholder, with: linkString)
        
        optInContent = content + "\n\n" + readTerms
    }
}
