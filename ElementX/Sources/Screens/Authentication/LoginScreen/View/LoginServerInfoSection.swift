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

import SwiftUI

/// A view that shows information about the chosen homeserver,
/// along with an edit button to pick a different one.
struct LoginServerInfoSection: View {
    // MARK: - Public
    
    /// The address shown for the server.
    let address: String
    /// The action performed when tapping the edit button.
    let editAction: () -> Void
    
    // MARK: - Views
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(ElementL10n.authenticationServerInfoTitle)
                .font(.element.subheadline)
                .foregroundColor(.element.secondaryContent)
            
            HStack {
                Text(address)
                    .font(.element.body)
                    .foregroundColor(.element.primaryContent)
                
                Spacer()
                
                Button(action: editAction) {
                    Text(ElementL10n.edit)
                        .padding(.vertical, 2)
                }
                .buttonStyle(.elementGhost())
                .accessibilityIdentifier("editServerButton")
            }
        }
    }
}
