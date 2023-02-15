//
// Copyright 2023 New Vector Ltd
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

struct SettingsRowLabelStyle: LabelStyle {
    @ScaledMetric private var menuIconSize = 30.0
    
    var alignment: VerticalAlignment = .firstTextBaseline

    func makeBody(configuration: Configuration) -> some View {
        HStack(alignment: alignment, spacing: 16) {
            configuration.icon
                .foregroundColor(.element.secondaryContent)
                .padding(4)
                .background(Color.element.formBackground)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .frame(width: menuIconSize, height: menuIconSize)
            configuration.title
                .font(.element.body)
                .foregroundColor(.element.primaryContent)
        }
    }
}
