//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import XCTest

@MainActor
class ReportProblemScreenViewModelTests: XCTestCase {
    var viewModel: ReportProblemScreenViewModelProtocol!
    var context: ReportProblemScreenViewModelType.Context!
    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        cancellables.removeAll()
        let clientProxy = ClientProxyMock(.init(userID: "@test:example.com", deviceID: "TESTDEVICEID"))
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        let userIndicatorController = UserIndicatorControllerMock()

        viewModel = ReportProblemScreenViewModel(userSession: userSession,
                                                 userIndicatorController: userIndicatorController)
        context = viewModel.context
    }

    func testInitialState() {
        XCTAssertFalse(context.viewState.diagnosticInfo.isEmpty, "Diagnostic info should be generated on init")
        XCTAssertTrue(context.viewState.diagnosticInfo.contains("@test:example.com"), "Diagnostic info should contain user ID")
        XCTAssertTrue(context.viewState.diagnosticInfo.contains("TESTDEVICEID"), "Diagnostic info should contain device ID")
        XCTAssertEqual(context.problemDescription, "", "Problem description should be empty initially")
        XCTAssertFalse(context.showShareSheet, "Share sheet should not be shown initially")
        XCTAssertEqual(context.viewState.reportTextForSharing, "", "Report text for sharing should be empty initially")
    }

    func testCopyToClipboard() {
        context.problemDescription = "Test problem description"
        context.send(viewAction: .copyToClipboard)

        let pasteboardString = UIPasteboard.general.string
        XCTAssertNotNil(pasteboardString, "Pasteboard should contain text after copy action")
        XCTAssertTrue(pasteboardString?.contains("Test problem description") ?? false, "Copied text should contain problem description")
        XCTAssertTrue(pasteboardString?.contains("Problem Description") ?? false, "Copied text should contain section header")
        XCTAssertTrue(pasteboardString?.contains("Diagnostic Information") ?? false, "Copied text should contain diagnostic info section")
        XCTAssertTrue(pasteboardString?.contains("@test:example.com") ?? false, "Copied text should contain user ID")
    }

    func testShareAction() {
        context.problemDescription = "Share test problem"
        XCTAssertFalse(context.showShareSheet, "Share sheet should not be shown initially")

        context.send(viewAction: .share)

        XCTAssertTrue(context.showShareSheet, "Share sheet should be shown after share action")
        XCTAssertFalse(context.viewState.reportTextForSharing.isEmpty, "Report text for sharing should not be empty")
        XCTAssertTrue(context.viewState.reportTextForSharing.contains("Share test problem"), "Report text should contain problem description")
        XCTAssertTrue(context.viewState.reportTextForSharing.contains("Problem Description"), "Report text should contain section header")
        XCTAssertTrue(context.viewState.reportTextForSharing.contains("Diagnostic Information"), "Report text should contain diagnostic info section")
    }
}
