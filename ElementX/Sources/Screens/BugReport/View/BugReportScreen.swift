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
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    mainContent
                        .padding(.top, 50)
                        .padding(.horizontal, horizontalPadding)
                }
                .introspectScrollView { scrollView in
                    scrollView.keyboardDismissMode = .onDrag
                }
                
                buttons
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
            }
            .navigationTitle(ElementL10n.titleActivityBugReport)
            .toolbar {
                if context.viewState.isModallyPresented {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(ElementL10n.actionCancel) {
                            context.send(viewAction: .cancel)
                        }
                    }
                }
            }
            .interactiveDismissDisabled()
        }
    }
    
    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ElementL10n.sendBugReportDescription)
                .accessibilityIdentifier("reportBugDescription")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color.element.system)

                if context.reportText.isEmpty {
                    Text(ElementL10n.sendBugReportPlaceholder)
                        .foregroundColor(Color.element.secondaryContent)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $context.reportText)
                    .padding(4)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .accessibilityIdentifier("reportTextView")
                    .introspectTextView { textView in
                        textView.backgroundColor = .clear
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .font(.body)
            Text(ElementL10n.sendBugReportLogsDescription)
                .accessibilityIdentifier("sendLogsDescription")
            HStack(spacing: 12) {
                Toggle(ElementL10n.sendBugReportIncludeLogs, isOn: $context.sendingLogsEnabled)
                    .toggleStyle(ElementToggleStyle())
                    .accessibilityIdentifier("sendLogsToggle")
                Text(ElementL10n.sendBugReportIncludeLogs).accessibilityIdentifier("sendLogsText")
            }
            .onTapGesture {
                context.send(viewAction: .toggleSendLogs)
            }
            screenshot
        }
    }
    
    /// The action buttons shown at the bottom of the view.
    var buttons: some View {
        VStack {
            Button { context.send(viewAction: .submit) } label: {
                Text(ElementL10n.actionSend)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .disabled(context.reportText.count < 5)
            .accessibilityIdentifier("sendButton")
        }
    }

    @ViewBuilder
    var screenshot: some View {
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
            .padding(.vertical, 10)
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
