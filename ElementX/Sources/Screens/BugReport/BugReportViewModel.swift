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

@available(iOS 14, *)
typealias BugReportViewModelType = StateStoreViewModel<BugReportViewState,
                                                                  BugReportViewAction>
@available(iOS 14, *)
class BugReportViewModel: BugReportViewModelType, BugReportViewModelProtocol {

    // MARK: - Properties

    let bugReportService: BugReportServiceProtocol

    // MARK: Private

    func submitBugReport() async {
        callback?(.submitStarted)
        do {
            var files: [URL] = []
            if let screenshot = state.screenshot {
                let anonymized = try await ImageAnonymizer.anonymizedImage(from: screenshot)
                let tmpUrl = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("screenshot").appendingPathExtension("png")
                //  remove old screenshot if exists
                if FileManager.default.fileExists(atPath: tmpUrl.path) {
                    try FileManager.default.removeItem(at: tmpUrl)
                }
                try anonymized.dataForPNGRepresentation().write(to: tmpUrl)
                files.append(tmpUrl)
            }

            let result = try await bugReportService.submitBugReport(text: context.reportText,
                                                                    includeLogs: context.sendingLogsEnabled,
                                                                    includeCrashLog: true,
                                                                    githubLabels: [],
                                                                    files: files)
            MXLog.info("[BugReportViewModel] submitBugReport succeeded, result: \(result.reportUrl)")
            callback?(.submitFinished)
        } catch let error {
            MXLog.error("[BugReportViewModel] submitBugReport failed: \(error)")
            callback?(.submitFailed(error: error))
        }
    }

    // MARK: Public

    var callback: ((BugReportViewModelAction) -> Void)?

    // MARK: - Setup

    init(bugReportService: BugReportServiceProtocol,
         screenshot: UIImage?) {
        self.bugReportService = bugReportService
        let bindings = BugReportViewStateBindings(reportText: "", sendingLogsEnabled: true)
        super.init(initialViewState: BugReportViewState(screenshot: screenshot,
                                                        bindings: bindings))
    }

    // MARK: - Public

    override func process(viewAction: BugReportViewAction) async {
        switch viewAction {
        case .submit:
            await submitBugReport()
        case .toggleSendLogs:
            context.sendingLogsEnabled.toggle()
        case .removeScreenshot:
            state.screenshot = nil
        }
    }
}
