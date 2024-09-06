//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct AnalyticsSettingsScreen: View {
    @ObservedObject var context: AnalyticsSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            analyticsSection
        }
        .compoundList()
        .navigationTitle(L10n.commonAnalytics)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    var analyticsSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenAnalyticsSettingsShareData),
                    kind: .toggle($context.enableAnalytics))
                .onChange(of: context.enableAnalytics) { _ in
                    context.send(viewAction: .toggleAnalytics)
                }
        } footer: {
            Text(context.viewState.strings.sectionFooter)
                .compoundListSectionFooter()
        }
    }
}

// MARK: - Previews

struct AnalyticsSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        let appSettings = AppSettings()
        let viewModel = AnalyticsSettingsScreenViewModel(appSettings: appSettings,
                                                         analytics: ServiceLocator.shared.analytics)
        AnalyticsSettingsScreen(context: viewModel.context)
    }
}
