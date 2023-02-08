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

/// Small squared action button style for settings screens
struct SettingsActionButtonStyle: ButtonStyle {
    let title: String
    
    @ScaledMetric private var menuIconSize = 54.0
    
    func makeBody(configuration: Configuration) -> some View {
        VStack {
            configuration.label
                .buttonStyle(.plain)
                .foregroundColor(.element.primaryContent)
                .frame(width: menuIconSize, height: menuIconSize)
                .background {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.element.background.opacity(configuration.isPressed ? 0.5 : 1))
                }
            
            Text(title)
                .foregroundColor(.element.secondaryContent)
                .font(.element.subheadline)
        }
    }
}
