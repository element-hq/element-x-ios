//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class DiagnosticsReportScreenViewModelTests: XCTestCase {
    func testInitialStateWithUserSession() {
        let clientProxy = ClientProxyMock(.init(userID: "@test:example.com", deviceID: "TESTDEVICE123"))
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        let viewModel = DiagnosticsReportScreenViewModel(userSession: userSession,
                                                         userIndicatorController: UserIndicatorControllerMock())
        let context = viewModel.context
        
        // Verify template is pre-filled
        XCTAssertFalse(context.reportText.isEmpty, "Report text should be pre-filled with diagnostics template")
        
        // Verify diagnostic info contains expected fields
        XCTAssertTrue(context.reportText.contains("@test:example.com"), "Report should contain user ID")
        XCTAssertTrue(context.reportText.contains("TESTDEVICE123"), "Report should contain device ID")
        XCTAssertTrue(context.reportText.contains("App:"), "Report should contain app version")
        XCTAssertTrue(context.reportText.contains("iOS:"), "Report should contain iOS version")
        XCTAssertTrue(context.reportText.contains("Device:"), "Report should contain device model")
        XCTAssertTrue(context.reportText.contains("Locale:"), "Report should contain locale")
        XCTAssertTrue(context.reportText.contains("Timezone:"), "Report should contain timezone")
        
        // Verify share sheet is not shown initially
        XCTAssertFalse(context.isSharePresented, "Share sheet should not be shown initially")
    }
    
    func testInitialStateWithoutUserSession() {
        let viewModel = DiagnosticsReportScreenViewModel(userSession: nil,
                                                         userIndicatorController: UserIndicatorControllerMock())
        let context = viewModel.context
        
        // Verify fallback values when no session
        XCTAssertTrue(context.reportText.contains(UntranslatedL10n.quickDiagnosticsNotLoggedIn), "Report should show localized 'Not logged in' when no session")
        XCTAssertTrue(context.reportText.contains(UntranslatedL10n.quickDiagnosticsUnknown), "Report should show localized 'Unknown' for device ID when no session")
    }
    
    func testCopyToClipboard() {
        let clientProxy = ClientProxyMock(.init(userID: "@test:example.com", deviceID: "TESTDEVICE123"))
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        let userIndicatorController = UserIndicatorControllerMock()
        let viewModel = DiagnosticsReportScreenViewModel(userSession: userSession,
                                                         userIndicatorController: userIndicatorController)
        let context = viewModel.context
        
        // Modify the report text
        context.reportText = "Test problem description\n---\nDiagnostics here"
        
        // Trigger copy action
        context.send(viewAction: .copyToClipboard)
        
        // Verify clipboard content
        let pasteboardString = UIPasteboard.general.string
        XCTAssertNotNil(pasteboardString, "Pasteboard should contain text after copy action")
        XCTAssertEqual(pasteboardString, "Test problem description\n---\nDiagnostics here", "Copied text should match report text")
        
        // Verify indicator was shown
        XCTAssertEqual(userIndicatorController.submitIndicatorDelayCallsCount, 1, "Should show copied indicator")
        XCTAssertEqual(userIndicatorController.submitIndicatorDelayReceivedArguments?.indicator.title, L10n.commonCopiedToClipboard)
    }
    
    func testShareAction() {
        let clientProxy = ClientProxyMock(.init(userID: "@test:example.com", deviceID: "TESTDEVICE123"))
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        let viewModel = DiagnosticsReportScreenViewModel(userSession: userSession,
                                                         userIndicatorController: UserIndicatorControllerMock())
        let context = viewModel.context
        
        // Verify share sheet is not shown initially
        XCTAssertFalse(context.isSharePresented, "Share sheet should not be shown initially")
        
        // Trigger share action
        context.send(viewAction: .share)
        
        // Verify share sheet is now shown
        XCTAssertTrue(context.isSharePresented, "Share sheet should be shown after share action")
    }
}
