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

struct AnalyticsPromptCheckmarkItem: View {
    // MARK: - Properties
    
    // MARK: Private
    
    private let attributedString: AttributedString
    
    // MARK: - Setup
    
    init(attributedString: AttributedString) {
        self.attributedString = attributedString
    }
    
    init(string: String) {
        attributedString = AttributedString(string)
    }
    
    // MARK: - Views
    
    var body: some View {
        Label { Text(attributedString) } icon: {
            Image(uiImage: Asset.Images.analyticsCheckmark.image)
                .foregroundColor(.element.accent)
        }
    }
}

// MARK: - Previews

struct AnalyticsPromptCheckmarkItem_Previews: PreviewProvider {
    static let strings = AnalyticsPromptStrings()
    
    static var previews: some View {
        VStack(alignment: .leading) {
            AnalyticsPromptCheckmarkItem(attributedString: strings.point1)
            AnalyticsPromptCheckmarkItem(attributedString: strings.point2)
            AnalyticsPromptCheckmarkItem(attributedString: AttributedString("This is a short string."))
            AnalyticsPromptCheckmarkItem(attributedString: AttributedString("This is a very long string that will be used to test the layout over multiple lines of text to ensure everything is correct."))
        }
        .padding()
    }
}
