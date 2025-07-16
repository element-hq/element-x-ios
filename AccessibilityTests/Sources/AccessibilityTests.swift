//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@MainActor
final class AccessibilityTests: XCTestCase {
    var app: XCUIApplication!
    
    func performAccessibilityAudit(named name: String) async throws {
        let client = try UITestsSignalling.Client(mode: .tests)
        app = Application.launch(viewID: name)
        await client.waitForApp()
        defer { try? client.stop() }
        
        // To handle system interrupts
        let allowButtonPredicate = NSPredicate(format: "label == 'Always Allow' || label == 'Allow'")
        _ = addUIInterruptionMonitor(withDescription: "Allow to access your location?") { alert -> Bool in
            let alwaysAllowButton = alert.buttons.matching(allowButtonPredicate).element.firstMatch
            if alwaysAllowButton.exists {
                alwaysAllowButton.tap()
                return true
            }
            return false
        }
        
        try client.send(.accessibilityAudit(.nextPreview))
        forLoop: for await signal in client.signals.values {
            switch signal {
            case .accessibilityAudit(let auditSignal):
                switch auditSignal {
                case .nextPreviewReady(let name):
                    // Alows us to log the name of the preview that is being tested
                    XCTContext.runActivity(named: name) { _ in
                        do {
                            // We have removed `textClipping` and `contrast` for now
                            try app.performAccessibilityAudit(for: [.dynamicType, .elementDetection, .hitRegion, .sufficientElementDescription, .trait]) { issue in
                                // Removew false positives for null elements
                                guard let element = issue.element else {
                                    return true
                                }
                                
                                // Filter out false positives for specific cases
                                if AccessibilityTests.ignoredA11yIdentifiers[element.identifier]?.contains(issue.auditType) == true {
                                    return true
                                }
                                
                                // We are fine with elements that only partially support dynamic types
                                guard issue.compactDescription != "Dynamic Type font sizes are partially unsupported" else {
                                    return true
                                }
                                
                                return false
                            }
                        } catch {
                            XCTFail("Failed to perform the accessibility audit: \(error)")
                        }
                    }
                    try? client.send(.accessibilityAudit(.nextPreview))
                case .noMorePreviews:
                    break forLoop
                default:
                    XCTFail("Unhandled signal")
                }
            default:
                XCTFail("Unhandled signal")
            }
        }
        
        app.terminate()
    }
    
    private static let ignoredA11yIdentifiers: [String: [XCUIAccessibilityAuditType]] = [A11yIdentifiers.authenticationStartScreen.appVersion: [.hitRegion]]
}
