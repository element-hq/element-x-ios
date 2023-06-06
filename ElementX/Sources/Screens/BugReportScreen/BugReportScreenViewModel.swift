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

import Combine
import SwiftUI

typealias BugReportScreenViewModelType = StateStoreViewModel<BugReportScreenViewState, BugReportScreenViewAction>

class BugReportScreenViewModel: BugReportScreenViewModelType, BugReportScreenViewModelProtocol {
    private let bugReportService: BugReportServiceProtocol
    private let userID: String
    private let deviceID: String?
    private let actionsSubject: PassthroughSubject<BugReportScreenViewModelAction, Never> = .init()

    var actions: AnyPublisher<BugReportScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(bugReportService: BugReportServiceProtocol,
         userID: String,
         deviceID: String?,
         screenshot: UIImage?,
         isModallyPresented: Bool) {
        self.bugReportService = bugReportService
        self.userID = userID
        self.deviceID = deviceID
        
        let bindings = BugReportScreenViewStateBindings(reportText: "", sendingLogsEnabled: true)
        super.init(initialViewState: BugReportScreenViewState(screenshot: screenshot,
                                                              bindings: bindings,
                                                              isModallyPresented: isModallyPresented))
    }
    
    // MARK: - Public
    
    override func process(viewAction: BugReportScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.cancel)
        case .submit:
            Task { await submitBugReport() }
        case .removeScreenshot:
            state.screenshot = nil
        case let .attachScreenshot(image):
            state.screenshot = image
        }
    }
    
    // MARK: Private

    private func submitBugReport() async {
        let progressTracker = ProgressTracker()
        actionsSubject.send(.submitStarted(progressTracker: progressTracker))
        
        var files: [URL] = []
        if let screenshot = context.viewState.screenshot,
           let pngData = screenshot.pngData() {
            let imageURL = URL.temporaryDirectory.appendingPathComponent("Screenshot.png")
            
            do {
                try pngData.write(to: imageURL)
                files.append(imageURL)
            } catch {
                MXLog.error("Failed writing screenshot to disk")
                // Continue anyway without the screenshot.
            }
        }
        let bugReport = BugReport(userID: userID,
                                  deviceID: deviceID,
                                  text: context.reportText,
                                  includeLogs: context.sendingLogsEnabled,
                                  includeCrashLog: true,
                                  githubLabels: [],
                                  files: files)
        
        switch await bugReportService.submitBugReport(bugReport,
                                                      progressListener: progressTracker) {
        case .success(let response):
            MXLog.info("Submission uploaded to: \(response.reportUrl)")
            actionsSubject.send(.submitFinished)
        case .failure(let error):
            MXLog.error("Submission failed: \(error)")
            actionsSubject.send(.submitFailed(error: error))
        }
    }
}
