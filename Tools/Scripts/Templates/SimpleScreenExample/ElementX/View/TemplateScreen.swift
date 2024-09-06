//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct TemplateScreen: View {
    @ObservedObject var context: TemplateScreenViewModel.Context
    
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
        .onChange(of: context.composerText) { _ in
            context.send(viewAction: .textChanged)
        }
    }
}

// MARK: - Previews

struct TemplateScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TemplateScreenViewModel()
    static var previews: some View {
        NavigationStack {
            TemplateScreen(context: viewModel.context)
        }
    }
}
