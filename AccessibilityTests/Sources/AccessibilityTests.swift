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
                    try? app.performAccessibilityAudit { issue in
                        XCTFail("\(name): \(issue)")
                        return true
                    }
                    try? client.send(.accessibilityAudit(.nextPreview))
                case .noMorePreviews:
                    break forLoop
                default:
                    fatalError("Unhandled signal")
                }
            default:
                fatalError("Unhandled signal")
            }
        }
        
        app.terminate()
    }
}
