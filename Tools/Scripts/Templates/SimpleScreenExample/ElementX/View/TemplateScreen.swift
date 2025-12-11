//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct TemplateScreen: View {
    @Bindable var context: TemplateScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                ListRow(label: .plain(title: context.viewState.placeholder),
                        kind: .textField(text: $context.composerText))
                
                ListRow(label: .centeredAction(title: L10n.actionDone,
                                               icon: \.leave),
                        kind: .button { context.send(viewAction: .done) })
            }
            
            Section {
                ListRow(label: .default(title: "Counter", icon: \.chart),
                        details: .counter(context.viewState.counter),
                        kind: .label)
                ListRow(label: .default(title: "Increment", icon: \.plus),
                        kind: .button { context.send(viewAction: .incrementCounter) })
                ListRow(label: .default(title: "Decrement", icon: \.minus),
                        kind: .button { context.send(viewAction: .decrementCounter) })
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

struct TemplateScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let incrementedViewModel = makeViewModel(counterValue: 1)
    
    static var previews: some View {
        NavigationStack {
            TemplateScreen(context: viewModel.context)
        }
        .previewDisplayName("Initial")
        
        NavigationStack {
            TemplateScreen(context: incrementedViewModel.context)
        }
        .previewDisplayName("Incremented")
        .snapshotPreferences(expect: incrementedViewModel.context.observe(\.viewState.counter).map { $0 == 1 })
    }
    
    static func makeViewModel(counterValue: Int = 0) -> TemplateScreenViewModel {
        let viewModel = TemplateScreenViewModel()
        
        for _ in 0..<counterValue {
            viewModel.context.send(viewAction: .incrementCounter)
        }
        
        return viewModel
    }
}
