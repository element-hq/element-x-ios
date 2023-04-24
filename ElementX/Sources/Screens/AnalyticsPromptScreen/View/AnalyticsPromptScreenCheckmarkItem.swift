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

import SwiftUI

struct AnalyticsPromptScreenCheckmarkItem: View {
    private let attributedString: AttributedString
    
    init(attributedString: AttributedString) {
        self.attributedString = attributedString
    }
    
    init(string: String) {
        attributedString = AttributedString(string)
    }
    
    var body: some View {
        Label { Text(attributedString) } icon: {
            Image(systemName: "checkmark.circle")
                .foregroundColor(.element.accent)
        }
    }
}

// MARK: - Previews

struct AnalyticsPromptScreenCheckmarkItem_Previews: PreviewProvider {
    static let strings = AnalyticsPromptScreenStrings(termsURL: ServiceLocator.shared.settings.analyticsConfiguration.termsURL)
    
    static var previews: some View {
        VStack(alignment: .leading) {
            AnalyticsPromptScreenCheckmarkItem(attributedString: strings.point1)
            AnalyticsPromptScreenCheckmarkItem(attributedString: strings.point2)
            AnalyticsPromptScreenCheckmarkItem(attributedString: AttributedString("This is a short string."))
            AnalyticsPromptScreenCheckmarkItem(attributedString: AttributedString("This is a very long string that will be used to test the layout over multiple lines of text to ensure everything is correct."))
        }
        .padding()
    }
}
