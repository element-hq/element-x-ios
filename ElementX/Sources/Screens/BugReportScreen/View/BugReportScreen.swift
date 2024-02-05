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
    
    @ObservedObject var context: BugReportScreenViewModel.Context
    
    var photosPickerTitle: String { context.viewState.screenshot == nil ? L10n.screenBugReportAttachScreenshot : L10n.screenBugReportEditScreenshot }
    
    var body: some View {
        Form {
            textFieldSection
            attachScreenshotSection
            sendLogsSection
            canContactSection
        }
        .disabled(context.viewState.shouldDisableInteraction)
        .scrollDismissesKeyboard(.immediately)
        .compoundList()
        .navigationTitle(L10n.commonReportAProblem)
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
            ListRow(label: .plain(title: L10n.screenBugReportEditorPlaceholder),
                    kind: .textField(text: $context.reportText, axis: .vertical))
                .lineLimit(4, reservesSpace: true)
                .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.report)
        } footer: {
            Text(L10n.screenBugReportEditorDescription)
                .compoundListSectionFooter()
        }
    }
    
    private var sendLogsSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenBugReportIncludeLogs),
                    kind: .toggle($context.sendingLogsEnabled))
                .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.sendLogs)
            ListRow(label: .plain(title: L10n.screenBugReportViewLogs),
                    kind: .navigationLink { context.send(viewAction: .viewLogs) })
                .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.sendLogs)
        } footer: {
            Text(L10n.screenBugReportLogsDescription)
                .compoundListSectionFooter()
        }
    }

    private var canContactSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenBugReportContactMeTitle),
                    kind: .toggle($context.canContact))
                .accessibilityIdentifier(A11yIdentifiers.bugReportScreen.canContact)
        } footer: {
            Text(L10n.screenBugReportContactMe)
                .compoundListSectionFooter()
        }
    }

    @ViewBuilder
    private var attachScreenshotSection: some View {
        Section {
            ListRow(kind: .custom {
                PhotosPicker(selection: $selectedScreenshot,
                             matching: .screenshots,
                             photoLibrary: .shared()) {
                    ListRowLabel.plain(title: photosPickerTitle)
                }
            })
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
                            CompoundIcon(\.close, size: .small, relativeTo: .compound.bodyMD)
                                .foregroundStyle(.compound.iconSecondary)
                                .background {
                                    Circle().fill(.compound.bgCanvasDefaultLevel1)
                                }
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
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionSend) {
                context.send(viewAction: .submit)
            }
            .disabled(context.reportText.count < 5)
            .disabled(context.viewState.shouldDisableInteraction)
        }
    }
}

// MARK: - Previews

struct BugReport_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        NavigationStack {
            BugReportScreen(context: BugReportScreenViewModel(bugReportService: BugReportServiceMock(),
                                                              userID: "@mock.client.com",
                                                              deviceID: nil,
                                                              screenshot: nil,
                                                              isModallyPresented: false).context)
                .previewDisplayName("Without Screenshot")
        }
        
        NavigationStack {
            BugReportScreen(context: BugReportScreenViewModel(bugReportService: BugReportServiceMock(),
                                                              userID: "@mock.client.com",
                                                              deviceID: nil,
                                                              screenshot: Asset.Images.appLogo.image,
                                                              isModallyPresented: false).context)
                .previewDisplayName("With Screenshot")
        }
    }
}
