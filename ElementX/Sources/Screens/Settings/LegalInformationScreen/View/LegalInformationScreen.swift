//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
                        kind: .button { openURL(context.viewState.copyrightURL) })
                // Tchap: Customize "About" menu into "Legal" menu
//                ListRow(label: .plain(title: L10n.commonAcceptableUsePolicy),
                ListRow(label: .plain(title: TchapL10n.legalTermsOfUse),
                        kind: .button { openURL(context.viewState.acceptableUseURL) })
                // Tchap: Customize "About" menu into "Legal" menu
//                ListRow(label: .plain(title: L10n.commonPrivacyPolicy),
                ListRow(label: .plain(title: TchapL10n.legalPrivacyPolicy),
                        kind: .button { openURL(context.viewState.privacyURL) })
            }
        }
        .compoundList()
        // Tchap: Customize "About" menu into "Legal" menu
        .navigationTitle(TchapL10n.commonLegal)
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Previews

struct LegalInformationScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = LegalInformationScreenViewModel(appSettings: AppSettings())
    static var previews: some View {
        LegalInformationScreen(context: viewModel.context)
    }
}
