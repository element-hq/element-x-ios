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
import PhotosUI
import SwiftUI

struct BugReportScreen: View {
    @State private var selectedScreenshot: PhotosPickerItem?
    
    @ObservedObject var context: BugReportViewModel.Context
    
    var body: some View {
        Form {
            textFieldSection
            
            attachScreenshotSection
            
            sendLogsSection
        }
        .scrollDismissesKeyboard(.immediately)
        .compoundForm()
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
    
    private var textFieldSection: some View {
        Section {
            TextField(ElementL10n.bugReportScreenEditorPlaceholder,
                      text: $context.reportText,
                      prompt: Text(ElementL10n.bugReportScreenEditorPlaceholder).foregroundColor(.compound.textPlaceholder),
                      axis: .vertical)
                .lineLimit(4, reservesSpace: true)
                .tint(.compound.iconAccentTertiary)
                .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.report)
        } footer: {
            Text(ElementL10n.bugReportScreenDescription)
                .compoundFormSectionFooter()
        }
        .compoundFormSection()
    }
    
    private var sendLogsSection: some View {
        Section {
            Toggle(ElementL10n.bugReportScreenIncludeLogs, isOn: $context.sendingLogsEnabled)
                .toggleStyle(.compoundForm())
                .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.sendLogs)
        } footer: {
            Text(ElementL10n.bugReportScreenLogsDescription)
                .compoundFormSectionFooter()
        }
        .compoundFormSection()
    }

    @ViewBuilder
    private var attachScreenshotSection: some View {
        Section {
            PhotosPicker(selection: $selectedScreenshot,
                         matching: .screenshots,
                         photoLibrary: .shared()) {
                Label(context.viewState.screenshot == nil ? ElementL10n.bugReportScreenAttachScreenshot : ElementL10n.bugReportScreenEditScreenshot, systemImage: "camera")
            }
            .buttonStyle(.compoundForm())
            .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.attachScreenshot)
        } footer: {
            if let screenshot = context.viewState.screenshot {
                Image(uiImage: screenshot)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 100)
                    .cornerRadius(4)
                    .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.screenshot)
                    .overlay(alignment: .topTrailing) {
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
        .compoundFormSection()
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
            BugReportScreen(context: BugReportViewModel(bugReportService: BugReportServiceMock(),
                                                        userID: "@mock.client.com",
                                                        deviceID: nil,
                                                        screenshot: Asset.Images.appLogo.image,
                                                        isModallyPresented: false).context)
                .previewDisplayName("With Screenshot")
        }
    }
}
