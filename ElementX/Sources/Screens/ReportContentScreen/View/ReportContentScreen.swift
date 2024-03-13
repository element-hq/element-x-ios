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

struct ReportContentScreen: View {
    @ObservedObject var context: ReportContentScreenViewModel.Context

    var body: some View {
        Form {
            reasonSection
            
            ignoreUserSection
        }
        .scrollDismissesKeyboard(.immediately)
        .compoundList()
        .navigationTitle(L10n.actionReportContent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .interactiveDismissDisabled()
    }

    private var reasonSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenReportContentHint),
                    kind: .textField(text: $context.reasonText, axis: .vertical))
                .lineLimit(4, reservesSpace: true)
        } footer: {
            Text(L10n.screenReportContentExplanation)
                .compoundListSectionFooter()
        }
    }
    
    private var ignoreUserSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenReportContentBlockUser),
                    kind: .toggle($context.ignoreUser))
                .accessibilityIdentifier(A11yIdentifiers.reportContent.ignoreUser)
        } footer: {
            Text(L10n.screenReportContentBlockUserHint)
                .compoundListSectionFooter()
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionSend) {
                context.send(viewAction: .submit)
            }
        }
    }
}

// MARK: - Previews

struct ReportContentScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ReportContentScreenViewModel(eventID: "",
                                                        senderID: "",
                                                        roomProxy: RoomProxyMock(with: .init()),
                                                        clientProxy: ClientProxyMock(.init()))
    
    static var previews: some View {
        NavigationStack {
            ReportContentScreen(context: viewModel.context)
        }
    }
}
