//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct SecurityAndPrivacyScreen: View {
    @ObservedObject var context: SecurityAndPrivacyScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                ListRow(label: .plain(title: context.viewState.placeholder),
                        kind: .textField(text: $context.composerText))
                
                ListRow(label: .centeredAction(title: L10n.actionDone,
                                               systemIcon: .doorLeftHandClosed),
                        kind: .button { context.send(viewAction: .done) })
            }
        }
        .compoundList()
        .navigationTitle(context.viewState.title)
        .onChange(of: context.composerText) {
            context.send(viewAction: .textChanged)
        }
    }
}

// MARK: - Previews

struct SecurityAndPrivacyScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = SecurityAndPrivacyScreenViewModel()
    static var previews: some View {
        NavigationStack {
            SecurityAndPrivacyScreen(context: viewModel.context)
        }
    }
}
