//
// Copyright 2025 Element Creations Ltd.
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
        
        try client.send(.accessibilityAudit(.nextPreview))
        
        // To handle location sharing popup in CI
        allowLocationPermissions()
        forLoop: for await signal in client.signals.values {
            switch signal {
            case .accessibilityAudit(let auditSignal):
                switch auditSignal {
                case .nextPreviewReady(let name):
                    performAccessibilityAuditForPreview(named: name)
                    try client.send(.accessibilityAudit(.nextPreview))
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
    
    private func allowLocationPermissions() {
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let notificationAlertAllowButton = springboard.buttons["Allow While Using App"].firstMatch
        if notificationAlertAllowButton.exists {
            notificationAlertAllowButton.tap()
        }
    }
    
    private func performAccessibilityAuditForPreview(named name: String) {
        // Alows us to log the name of the preview that is being tested
        XCTContext.runActivity(named: name) { _ in
            do {
                // We have removed `textClipped` and `contrast` for now
                try app.performAccessibilityAudit(for: [.dynamicType, .elementDetection, .hitRegion, .sufficientElementDescription, .trait]) { issue in
                    // Specific tests do not need specific accessibilty audit types
                    if Self.ignoredA11yTest[name]?.isAccessibilityIssueFiltered(issue) == true {
                        return true
                    }
                    
                    // Remove false positives for null elements
                    guard let element = issue.element else {
                        return true
                    }
                    
                    // We are fine with elements that only partially support dynamic types
                    guard issue.compactDescription != Self.partiallyUnsupportedDynamicTypeMessage else {
                        return true
                    }
                    
                    // We can filter out matrix entities from the non human-readable error
                    if issue.compactDescription == Self.notHumanReadableMessage, Self.isMatrixIdentifier(element.label) {
                        return true
                    }
                    
                    // Additional filters for specific elements that lead to false positives or neglectable issues.
                    if Self.ignoredA11yIdentifiers[element.identifier]?.isAccessibilityIssueFiltered(issue) == true {
                        return true
                    }
                    
                    return false
                }
            } catch {
                XCTFail("Failed to perform the accessibility audit: \(error)")
            }
        }
    }
    
    private static func isMatrixIdentifier(_ string: String) -> Bool {
        MatrixEntityRegex.isMatrixRoomAlias(string) || MatrixEntityRegex.isMatrixUserIdentifier(string) || string == PillUtilities.atRoom || MatrixEntityRegex.isLegacyMatrixRoomID(string)
    }
    
    private static let partiallyUnsupportedDynamicTypeMessage = "Dynamic Type font sizes are partially unsupported"
    private static let notHumanReadableMessage = "Label not human-readable"
    private static let elementHasNoDescription = "Element has no description"
    
    /// Use this array to filter add specific filters to ignore specific issues for certain elements
    private static let ignoredA11yIdentifiers: [String: [FilterType]] = [
        A11yIdentifiers.serverConfirmationScreen.serverPicker: [.compactDescription(notHumanReadableMessage)]
    ]
    
    /// Use this array to filter add specific filters to ignore specific tests
    private static let ignoredA11yTest: [String: [FilterType]] = [
        // It's an image rendering test doesn't need to have descriptions
        "RoomAvatarImage_Previews-0": [.auditType(.sufficientElementDescription)]
    ]
}

private enum FilterType {
    /// Filter by the content of the compactDescription of the issue
    case compactDescription(String)
    /// Filter by the type of the issue
    case auditType(XCUIAccessibilityAuditType)
}

private extension Array where Element == FilterType {
    func isAccessibilityIssueFiltered(_ issue: XCUIAccessibilityAuditIssue) -> Bool {
        for filter in self {
            switch filter {
            case .auditType(issue.auditType):
                return true
            case .compactDescription(issue.compactDescription):
                return true
            default:
                break
            }
        }
        return false
    }
}
