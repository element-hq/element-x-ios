// 
// Copyright 2021 New Vector Ltd
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

struct BugReport: View {

    // MARK: Private
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @State private var textStyle = UIFont.TextStyle.body
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 16
    }
    
    // MARK: Public
    
    @ObservedObject var context: BugReportViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView(showsIndicators: false) {
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
        }
    }
    
    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ElementL10n.sendBugReportDescription)
                .accessibilityIdentifier("Report Bug")
            ZStack(alignment: .topLeading) {
                RoundedRectangle(cornerRadius: 8, style: .continuous)
                    .fill(Color(UIColor.secondarySystemBackground))

                if context.reportText.isEmpty {
                    Text(ElementL10n.sendBugReportPlaceholder)
                        .foregroundColor(Color(UIColor.placeholderText))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 12)
                }
                TextEditor(text: $context.reportText)
                    .padding(4)
                    .background(Color.clear)
                    .cornerRadius(8)
                    .accessibilityLabel("Report")
                    .introspectTextView { textView in
                        textView.backgroundColor = .clear
                    }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 300)
            .font(.body)
            Text(ElementL10n.sendBugReportLogsDescription)
            HStack(spacing: 12) {
                sendLogsImage
                    .foregroundColor(Color(Asset.Colors.elementGreen.color))
                Text(ElementL10n.sendBugReportIncludeLogs).accessibilityLabel("Send Logs")
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
            .accessibilityLabel("Send")

            Button { context.send(viewAction: .cancel) } label: {
                Text(ElementL10n.actionCancel)
                    .padding(.vertical, 12)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .accessibilityLabel("Cancel")
        }
    }

    var sendLogsImage: some View {
        if context.sendingLogsEnabled {
            return Image(uiImage: Asset.Images.selectionTick.image)
                .accessibilityLabel("Disable Sending Logs")
        } else {
            return Image(uiImage: Asset.Images.selectionUntick.image)
                .accessibilityLabel("Enable Sending Logs")
        }
    }

    var screenshot: some View {
        if let screenshot = context.screenshot {
            return AnyView(
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: screenshot)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .accessibilityLabel("Screenshot")
                    Button { context.send(viewAction: .removeScreenshot) } label: {
                        Image(uiImage: Asset.Images.closeCircle.image)
                    }
                    .padding(.top, -10)
                    .padding(.trailing, -10)
                    .accessibilityLabel("Remove Screenshot")
                }
                .padding(.vertical, 10)
            )
        }
        return AnyView(EmptyView())
    }
}

// MARK: - Previews

struct BugReport_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let viewModel = BugReportViewModel(bugReportService: MockBugReportService(), screenshot: Asset.Images.sampleScreenshot.image)
            BugReport(context: viewModel.context)
                .previewInterfaceOrientation(.portrait)
        }
    }
}
