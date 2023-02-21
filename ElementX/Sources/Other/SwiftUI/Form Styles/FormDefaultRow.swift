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

/// Default row that can be reused for forms.
struct FormDefaultRow: View {
    // MARK: Public
    
    let title: String
    let image: Image
    var accessory: FormRowAccessory?
    let action: () -> Void

    // MARK: Views
    
    var body: some View {
        Button(action: action) {
            Label { Text(title) } icon: { image }
        }
        .buttonStyle(FormButtonStyle(accessory: accessory))
        .listRowInsets(EdgeInsets()) // Remove insets to use button background.
        .foregroundColor(.element.primaryContent)
    }
}

struct SettingsDefaultRow_Previews: PreviewProvider {
    static var previews: some View {
        Form {
            Section {
                FormDefaultRow(title: "Sign out", image: Image(systemName: "person")) { }
                FormDefaultRow(title: "Sign out", image: Image(systemName: "person"), accessory: .navigationLink) { }
            }
        }
    }
}
