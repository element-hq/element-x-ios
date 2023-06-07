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

struct LegalInformationScreen: View {
    @ObservedObject var context: LegalInformationScreenViewModel.Context
    @Environment(\.openURL) private var openURL
    
    var body: some View {
        Form {
            Section {
                Button(L10n.commonCopyright) {
                    openURL(URL(staticString: "https://element.io/copyright"))
                }
                Button(L10n.commonAcceptableUsePolicy) {
                    openURL(URL(staticString: "https://element.io/acceptable-use-policy-terms"))
                }
                Button(L10n.commonPrivacyPolicy) {
                    openURL(URL(staticString: "https://element.io/privacy"))
                }
            }
            .buttonStyle(.compoundForm(accessory: .navigationLink))
            .compoundFormSection()
        }
        .compoundForm()
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
