//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct AdvancedSettingsScreen: View {
    @ObservedObject var context: AdvancedSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                ListRow(label: .plain(title: L10n.commonAppearance),
                        kind: .picker(selection: $context.appAppearance,
                                      items: AppAppearance.allCases.map { (title: $0.name, tag: $0) }))
                
                ListRow(label: .plain(title: L10n.actionViewSource,
                                      description: L10n.screenAdvancedSettingsViewSourceDescription),
                        kind: .toggle($context.viewSourceEnabled))
                
                ListRow(label: .plain(title: L10n.screenAdvancedSettingsSharePresence,
                                      description: L10n.screenAdvancedSettingsSharePresenceDescription),
                        kind: .toggle($context.sharePresence))
                
                ListRow(label: .plain(title: L10n.screenAdvancedSettingsMediaCompressionTitle,
                                      description: L10n.screenAdvancedSettingsMediaCompressionDescription),
                        kind: .toggle($context.optimizeMediaUploads))
                    .onChange(of: context.optimizeMediaUploads) {
                        context.send(viewAction: .optimizeMediaUploadsChanged)
                    }
            }
        }
        .compoundList()
        .navigationTitle(L10n.commonAdvancedSettings)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private extension AppAppearance {
    var name: String {
        switch self {
        case .system:
            return L10n.commonSystem
        case .light:
            return L10n.commonLight
        case .dark:
            return L10n.commonDark
        }
    }
}

// MARK: - Previews

struct AdvancedSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = AdvancedSettingsScreenViewModel(advancedSettings: ServiceLocator.shared.settings,
                                                           analytics: ServiceLocator.shared.analytics)
    static var previews: some View {
        NavigationStack {
            AdvancedSettingsScreen(context: viewModel.context)
        }
    }
}
