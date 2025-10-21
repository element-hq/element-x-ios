//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct AnalyticsSettingsScreenViewState: BindableState {
    /// Attributed strings created from localized HTML.
    let strings: AnalyticsSettingsScreenStrings
    var bindings: AnalyticsSettingsScreenViewStateBindings
}

struct AnalyticsSettingsScreenViewStateBindings {
    var enableAnalytics: Bool
}

enum AnalyticsSettingsScreenViewAction {
    case toggleAnalytics
}

struct AnalyticsSettingsScreenStrings {
    let sectionFooter: AttributedString
    
    init(termsURL: URL?) {
        let content = AttributedString(L10n.screenAnalyticsPromptHelpUsImprove)
        
        if let termsURL {
            // Create the 'read terms' with a placeholder.
            let linkPlaceholder = "{link}"
            var readTerms = AttributedString(L10n.screenAnalyticsSettingsReadTerms(linkPlaceholder))
            var linkString = AttributedString(L10n.screenAnalyticsSettingsReadTermsContentLink)
            linkString.link = termsURL
            linkString.bold()
            readTerms.replace(linkPlaceholder, with: linkString)
            
            sectionFooter = content + "\n\n" + readTerms
        } else {
            sectionFooter = content
        }
    }
}
