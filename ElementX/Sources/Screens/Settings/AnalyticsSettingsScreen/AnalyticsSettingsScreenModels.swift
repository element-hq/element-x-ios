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
    
    init(termsURL: URL) {
        let content = AttributedString(L10n.screenAnalyticsPromptHelpUsImprove)
        
        // Create the 'read terms' with a placeholder.
        let linkPlaceholder = "{link}"
        var readTerms = AttributedString(L10n.screenAnalyticsSettingsReadTerms(linkPlaceholder))
        var linkString = AttributedString(L10n.screenAnalyticsSettingsReadTermsContentLink)
        linkString.link = termsURL
        linkString.bold()
        readTerms.replace(linkPlaceholder, with: linkString)
        
        sectionFooter = content + "\n\n" + readTerms
    }
}
