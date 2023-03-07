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

import PhotosUI
import SwiftUI

struct BugReportScreen: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 16
    }

    @State private var selectedScreenshot: PhotosPickerItem?
    
    @ObservedObject var context: BugReportViewModel.Context
    
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
        .onChange(of: selectedScreenshot) { newItem in
            Task {
                guard let data = try? await newItem?.loadTransferable(type: Data.self),
                      let image = UIImage(data: data)
                else {
                    return
                }
                context.send(viewAction: .attachScreenshot(image))
            }
        }
    }

    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(alignment: .leading, spacing: 24) {
            descriptionTextEditor
            attachScreenshot
            sendLogsToggle
        }
    }
    
    private var descriptionTextEditor: some View {
        FormTextEditor(text: $context.reportText,
                       placeholder: ElementL10n.bugReportScreenDescription,
                       editorAccessibilityIdentifier: A11yIdentifiers.bugReportScreen.report)
    }
    
    @ViewBuilder
    private var sendLogsToggle: some View {
        VStack(spacing: 8) {
            Toggle(ElementL10n.bugReportScreenIncludeLogs, isOn: $context.sendingLogsEnabled)
                .foregroundColor(.element.primaryContent)
                .tint(Color.element.brand)
                .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.sendLogs)
                .padding(.horizontal, 16)
                .padding(.vertical, 6.5)
                .background {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(Color.element.formRowBackground)
                }
            
            Text(ElementL10n.bugReportScreenLogsDescription)
                .font(.element.caption1)
                .foregroundColor(Color.element.secondaryContent)
                .padding(.horizontal, -8)
        }
    }

    @ViewBuilder
    private var attachScreenshot: some View {
        VStack(alignment: .leading, spacing: 16) {
            PhotosPicker(selection: $selectedScreenshot,
                         matching: .screenshots,
                         photoLibrary: .shared()) {
                HStack(spacing: 16) {
                    Label(context.viewState.screenshot == nil ? ElementL10n.bugReportScreenAttachScreenshot : ElementL10n.bugReportScreenEditScreenshot, systemImage: "camera")
                        .labelStyle(FormRowLabelStyle())
                    Spacer()
                }
            }
            .buttonStyle(FormButtonStyle())
            .background(Color.element.formRowBackground)
            .cornerRadius(14)
            .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.attachScreenshot)
            if let screenshot = context.viewState.screenshot {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: screenshot)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 100)
                        .cornerRadius(4)
                        .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.screenshot)
                    Button { context.send(viewAction: .removeScreenshot) } label: {
                        Image(Asset.Images.closeCircle.name)
                    }
                    .offset(x: 10, y: -10)
                    .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.removeScreenshot)
                }
                .padding(.vertical, 16)
                .padding(.horizontal, 16)
            }
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
        }
    }
}

// MARK: - Previews

struct BugReport_Previews: PreviewProvider {
    static let viewModel = BugReportViewModel(bugReportService: BugReportServiceMock(),
                                              userID: "@mock.client.com",
                                              deviceID: nil,
                                              screenshot: nil,
                                              isModallyPresented: false)
    
    static var previews: some View {
        NavigationStack {
            BugReportScreen(context: BugReportViewModel(bugReportService: BugReportServiceMock(),
                                                        userID: "@mock.client.com",
                                                        deviceID: nil,
                                                        screenshot: nil,
                                                        isModallyPresented: false).context)
                .previewDisplayName("Without Screenshot")
        }
        
        NavigationStack {
            BugReportScreen(context: BugReportViewModel(bugReportService: BugReportServiceProtocolMock(),
                                                        userID: "@mock.client.com",
                                                        deviceID: nil,
                                                        screenshot: Asset.Images.appLogo.image,
                                                        isModallyPresented: false).context)
                .previewDisplayName("With Screenshot")
        }
    }
}
