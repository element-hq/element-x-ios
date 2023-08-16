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

import Compound
import SwiftUI

struct LegalInformationScreen: View {
    @ObservedObject var context: LegalInformationScreenViewModel.Context
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Form {
            Section {
                ListRow(label: .plain(title: L10n.commonCopyright),
                        kind: .navigationLink { openURL("https://element.io/copyright") })
                ListRow(label: .plain(title: L10n.commonAcceptableUsePolicy),
                        kind: .navigationLink { openURL("https://element.io/acceptable-use-policy-terms") })
                ListRow(label: .plain(title: L10n.commonPrivacyPolicy),
                        kind: .navigationLink { openURL("https://element.io/privacy") })
            }
        }
        .compoundList()
        .navigationTitle(L10n.commonAbout)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

struct LegalInformationScreen_Previews: PreviewProvider {
    static let viewModel = LegalInformationScreenViewModel()
    static var previews: some View {
        LegalInformationScreen(context: viewModel.context)
    }
}
