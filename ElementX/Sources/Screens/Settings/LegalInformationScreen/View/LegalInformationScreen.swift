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
                ZeroListRow(label: .plain(title: L10n.commonCopyright),
                        kind: .button { openURL(context.viewState.copyrightURL) })
                ZeroListRow(label: .plain(title: L10n.commonAcceptableUsePolicy),
                        kind: .button { openURL(context.viewState.acceptableUseURL) })
                ZeroListRow(label: .plain(title: L10n.commonPrivacyPolicy),
                        kind: .button { openURL(context.viewState.privacyURL) })
            }
        }
        .zeroList()
        .navigationTitle(L10n.commonAbout)
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
