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
        .navigationTitle(ElementL10n.reportContent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .interactiveDismissDisabled()
    }

    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            infoText
            reasonTextEditor
        }
    }

    private var infoText: some View {
        Text(ElementL10n.reportContentInfo)
            .font(.element.body)
            .foregroundColor(Color.element.primaryContent)
    }

    private var reasonTextEditor: some View {
        FormTextEditor(text: $context.reasonText, placeholder: ElementL10n.reportContentCustomHint)
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

struct ReportContent_Previews: PreviewProvider {
    static let viewModel = ReportContentViewModel(itemID: "", roomProxy: RoomProxyMock(with: .init(displayName: nil)))
    
    static var previews: some View {
        ReportContentScreen(context: viewModel.context)
    }
}
