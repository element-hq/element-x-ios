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
                                                         analytics: AnalyticsService(client: AnalyticsClientMock(),
                                                                                     appSettings: appSettings,
                                                                                     bugReportService: BugReportServiceMock()))
        AnalyticsSettingsScreen(context: viewModel.context)
    }
}
