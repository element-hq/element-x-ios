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

struct BugReportScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 16
    }
    
    @ObservedObject var context: BugReportViewModel.Context
    
    var body: some View {
        ScrollView {
            mainContent
                .padding(.top, 50)
                .padding(.horizontal, horizontalPadding)
        }
        .scrollDismissesKeyboard(.immediately)
        .background(Color.element.system)
        .navigationTitle(ElementL10n.bugReportScreenTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .interactiveDismissDisabled()
    }

    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            descriptionTextEditor
            sendLogsToggle
            screenshot
        }
    }
    
    @ViewBuilder
    private var descriptionTextEditor: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(Color.element.background)

            TextEditor(text: $context.reportText)
                .tint(.element.brand)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(Color.clear)
                .cornerRadius(14)
                .accessibilityIdentifier("reportTextView")
                .introspectTextView { textView in
                    textView.backgroundColor = .clear
                }

            if context.reportText.isEmpty {
                Text(ElementL10n.bugReportScreenDescription)
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
        .frame(height: 300)
        .font(.body)
    }
    
    @ViewBuilder
    private var sendLogsToggle: some View {
        VStack(spacing: 8) {
            Toggle(ElementL10n.bugReportScreenIncludeLogs, isOn: $context.sendingLogsEnabled)
                .tint(Color.element.brand)
                .accessibilityIdentifier("sendLogsToggle")
                .padding(.horizontal, 16)
                .padding(.vertical, 11)
                .background(RoundedRectangle(cornerRadius: 14).fill(Color.element.background))
                .onTapGesture {
                    context.sendingLogsEnabled.toggle()
                }
            
            Text(ElementL10n.bugReportScreenLogsDescription)
                .font(.element.caption1)
                .foregroundColor(Color.element.secondaryContent)
                .padding(.horizontal, -8)
        }
    }
    
    @ViewBuilder
    private var screenshot: some View {
        if let screenshot = context.viewState.screenshot {
            ZStack(alignment: .topTrailing) {
                Image(uiImage: screenshot)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .accessibilityIdentifier("screenshotImage")
                Button { context.send(viewAction: .removeScreenshot) } label: {
                    Image(uiImage: Asset.Images.closeCircle.image)
                }
                .offset(x: 10, y: -10)
                .accessibilityIdentifier("removeScreenshotButton")
            }
            .padding(.vertical, 16)
            .padding(.horizontal, 16)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if context.viewState.isModallyPresented {
            ToolbarItem(placement: .cancellationAction) {
                Button(ElementL10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(ElementL10n.actionSend) {
                context.send(viewAction: .submit)
            }
            .disabled(context.reportText.count < 5)
            .accessibilityIdentifier("sendButton")
        }
    }
}

// MARK: - Previews

struct BugReport_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = BugReportViewModel(bugReportService: MockBugReportService(), screenshot: Asset.Images.appLogo.image, isModallyPresented: false)
        BugReportScreen(context: viewModel.context)
            .previewInterfaceOrientation(.portrait)
    }
}
