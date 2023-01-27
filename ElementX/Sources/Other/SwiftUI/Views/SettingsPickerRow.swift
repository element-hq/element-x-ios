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

/// Picker row that can be reused for settings screens
struct SettingsPickerRow<SelectionValue: Hashable, Content: View>: View {
    // MARK: Public
    
    let title: String
    let image: Image
    @Binding var selection: SelectionValue
    let content: () -> Content
    
    // MARK: Private
    
    @ScaledMetric private var menuIconSize = 30.0
    private let listRowInsets = EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16)

    // MARK: Views
    
    var body: some View {
        Picker(selection: $selection, content: content) {
            HStack(spacing: 16) {
                image
                    .foregroundColor(.element.systemGray)
                    .padding(4)
                    .background(Color.element.systemGray6)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(width: menuIconSize, height: menuIconSize)
                
                Text(title)
                    .font(.element.body)
                    .foregroundColor(.element.primaryContent)
            }
        }
        .listRowInsets(listRowInsets)
        .listRowSeparator(.hidden)
    }
}
