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

struct ReportContentScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    @ObservedObject var context: ReportContentViewModel.Context
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 16
    }

    var body: some View {
        ScrollView {
            mainContent
                .padding(.top, 50)
                .padding(.horizontal, horizontalPadding)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color.element.formBackground.ignoresSafeArea())
        .navigationTitle(ElementL10n.bugReportScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .interactiveDismissDisabled()
    }

    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            Text(ElementL10n.reportContentInfo)
                .font(.element.body)
                .foregroundColor(Color.element.primaryContent)
            descriptionTextEditor
        }
    }

    @ViewBuilder
    private var descriptionTextEditor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.element.formRowBackground)

            TextEditor(text: $context.reasonText)
                .tint(.element.brand)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .cornerRadius(14)
                .accessibilityIdentifier(A11yIdentifiers.reportContentScreen.reason)
                .scrollContentBackground(.hidden)

            if context.reasonText.isEmpty {
                Text(ElementL10n.reportContentCustomHint)
                    .font(.element.body)
                    .foregroundColor(Color.element.secondaryContent)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .allowsHitTesting(false)
            }

            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .stroke(Color.element.quaternaryContent)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 220)
        .font(.body)
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(ElementL10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(ElementL10n.actionSend) {
                context.send(viewAction: .submit)
            }
            .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.send)
        }
    }
}

// MARK: - Previews

struct ReportContent_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let viewModel = ReportContentViewModel()
            ReportContentScreen(context: viewModel.context)
        }
    }
}
