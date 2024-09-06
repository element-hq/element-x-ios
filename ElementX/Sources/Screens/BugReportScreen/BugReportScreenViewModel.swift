//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias BugReportScreenViewModelType = StateStoreViewModel<BugReportScreenViewState, BugReportScreenViewAction>

class BugReportScreenViewModel: BugReportScreenViewModelType, BugReportScreenViewModelProtocol {
    private let bugReportService: BugReportServiceProtocol
    private let clientProxy: ClientProxyProtocol?
    
    private let actionsSubject: PassthroughSubject<BugReportScreenViewModelAction, Never> = .init()
    // periphery:ignore - when set to nil this is automatically cancelled
    @CancellableTask private var uploadTask: Task<Void, Never>?

    var actions: AnyPublisher<BugReportScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(bugReportService: BugReportServiceProtocol,
         clientProxy: ClientProxyProtocol?,
         screenshot: UIImage?,
         isModallyPresented: Bool) {
        self.bugReportService = bugReportService
        self.clientProxy = clientProxy
        
        let bindings = BugReportScreenViewStateBindings(reportText: "", sendingLogsEnabled: true, canContact: false)
        super.init(initialViewState: BugReportScreenViewState(screenshot: screenshot,
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
        let ed25519 = await clientProxy?.ed25519Base64()
        let curve25519 = await clientProxy?.curve25519Base64()
        let bugReport = BugReport(userID: clientProxy?.userID,
                                  deviceID: clientProxy?.deviceID,
                                  ed25519: ed25519,
                                  curve25519: curve25519,
                                  text: context.reportText,
                                  includeLogs: context.sendingLogsEnabled,
                                  canContact: context.canContact,
                                  githubLabels: [],
                                  files: files)
        
        switch await bugReportService.submitBugReport(bugReport,
                                                      progressListener: progressSubject) {
        case .success(let response):
            MXLog.info("Submission uploaded to: \(response.reportUrl)")
            actionsSubject.send(.submitFinished)
        case .failure(let error):
            MXLog.error("Submission failed: \(error)")
            actionsSubject.send(.submitFailed(error: error))
            state.shouldDisableInteraction = false
        }
    }
}
