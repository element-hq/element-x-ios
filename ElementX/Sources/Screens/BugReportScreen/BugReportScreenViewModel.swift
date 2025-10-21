//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias BugReportScreenViewModelType = StateStoreViewModelV2<BugReportScreenViewState, BugReportScreenViewAction>

class BugReportScreenViewModel: BugReportScreenViewModelType, BugReportScreenViewModelProtocol {
    private let bugReportService: BugReportServiceProtocol
    private let clientProxy: ClientProxyProtocol?
    
    private let logFiles: [URL]
    
    private let actionsSubject: PassthroughSubject<BugReportScreenViewModelAction, Never> = .init()
    // periphery:ignore - when set to nil this is automatically cancelled
    @CancellableTask private var uploadTask: Task<Void, Never>?

    var actions: AnyPublisher<BugReportScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(bugReportService: BugReportServiceProtocol,
         clientProxy: ClientProxyProtocol?,
         logFiles: [URL] = Tracing.logFiles,
         screenshot: UIImage?,
         isModallyPresented: Bool) {
        self.bugReportService = bugReportService
        self.clientProxy = clientProxy
        self.logFiles = logFiles
        
        let canSendLogFiles = Self.validate(logFiles)
        let bindings = BugReportScreenViewStateBindings(reportText: "", sendingLogsEnabled: canSendLogFiles, canContact: false)
        super.init(initialViewState: BugReportScreenViewState(canSendLogFiles: canSendLogFiles,
                                                              screenshot: screenshot,
                                                              bindings: bindings,
                                                              isModallyPresented: isModallyPresented))
    }
    
    // MARK: - Public
    
    override func process(viewAction: BugReportScreenViewAction) {
        switch viewAction {
        case .cancel:
            uploadTask = nil
            actionsSubject.send(.cancel)
        case .viewLogs:
            actionsSubject.send(.viewLogs)
        case .submit:
            state.shouldDisableInteraction = true
            uploadTask = Task { await submitBugReport() }
        case .removeScreenshot:
            state.screenshot = nil
        case let .attachScreenshot(image):
            state.screenshot = image
        }
    }
    
    // MARK: Private
    
    /// Kind of a hack - when a log file balloons in size (e.g. due to a tight loop) the app is terminated by iOS for using
    /// too much memory. This is because we compare the file size against the upload limit **after** compressing it,
    /// but in order to compress it we load the whole file into memory.
    ///
    /// We could fix that, but then the problematic log file would be silently dropped and in reality it is much more valuable
    /// to have the user contact us to say there's an issue with their logs so we can actually fix whatever is generating the
    /// excessively large log files.
    private static func validate(_ logFiles: [URL]) -> Bool {
        for fileURL in logFiles {
            if let size = try? FileManager.default.sizeForItem(at: fileURL),
               size > 1024 * 1024 * 1024 { // Consider anything over 1GB to be excessive.
                return false
            }
        }
        return true
    }

    private func submitBugReport() async {
        let progressSubject = CurrentValueSubject<Double, Never>(0.0)
        
        actionsSubject.send(.submitStarted(progressPublisher: progressSubject.asCurrentValuePublisher()))
        
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
        
        let bugReport = await BugReport(userID: clientProxy?.userID,
                                        deviceID: clientProxy?.deviceID,
                                        ed25519: clientProxy?.ed25519Base64(),
                                        curve25519: clientProxy?.curve25519Base64(),
                                        text: context.reportText,
                                        logFiles: context.sendingLogsEnabled ? logFiles : nil,
                                        canContact: context.canContact,
                                        githubLabels: [],
                                        files: files)
        
        switch await bugReportService.submitBugReport(bugReport,
                                                      progressListener: progressSubject) {
        case .success(let response):
            MXLog.info("Submission uploaded: \(response.reportURL ?? "The server didn't generate a report URL")")
            actionsSubject.send(.submitFinished)
        case .failure(let error):
            MXLog.error("Submission failed: \(error)")
            actionsSubject.send(.submitFailed(error: error))
            state.shouldDisableInteraction = false
        }
    }
}
