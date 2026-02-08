//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

class BugReportPreflightTests: XCTestCase {
    // MARK: - Redactor Tests

    func testRedactorRedactsEmail() {
        let input = "Contact me at user@example.com for details"
        let result = Redactor.redact(input)
        XCTAssertFalse(result.contains("user@example.com"))
        XCTAssertTrue(result.contains("<redacted-email>"))
    }

    func testRedactorRedactsURL() {
        let input = "Visit https://element.io/help for support"
        let result = Redactor.redact(input)
        XCTAssertFalse(result.contains("https://element.io/help"))
        XCTAssertTrue(result.contains("<redacted-url>"))
    }

    func testRedactorRedactsMatrixID() {
        let input = "User @alice:matrix.org reported the issue"
        let result = Redactor.redact(input)
        XCTAssertFalse(result.contains("@alice:matrix.org"))
        XCTAssertTrue(result.contains("<redacted-matrix-id>"))
    }

    func testRedactorRedactsMultipleSensitiveItems() {
        let input = "User @bob:server.com sent email to admin@test.org and visited https://example.com/page"
        let result = Redactor.redact(input)
        XCTAssertFalse(result.contains("@bob:server.com"))
        XCTAssertFalse(result.contains("admin@test.org"))
        XCTAssertFalse(result.contains("https://example.com/page"))
    }

    func testRedactorPreservesNonSensitiveText() {
        let input = "App crashed on launch with error code 42"
        let result = Redactor.redact(input)
        XCTAssertEqual(result, input)
    }

    // MARK: - Report Format Tests

    func testBuildReportDeterministicFormat() {
        let summary = "App crashes on startup"
        let steps = "1. Open app\n2. Tap settings"
        let expected = "Settings screen appears"
        let actual = "App crashes with error"
        let diagnostics = "App Version: 1.0.0 (100)\nOS: iOS 17.0"

        let report1 = BugReportPreflightScreenViewModel.buildReport(summary: summary,
                                                                    stepsToReproduce: steps,
                                                                    expectedResult: expected,
                                                                    actualResult: actual,
                                                                    diagnosticsText: diagnostics)

        let report2 = BugReportPreflightScreenViewModel.buildReport(summary: summary,
                                                                    stepsToReproduce: steps,
                                                                    expectedResult: expected,
                                                                    actualResult: actual,
                                                                    diagnosticsText: diagnostics)

        XCTAssertEqual(report1, report2)
    }

    func testBuildReportContainsAllSections() {
        let summary = "Test summary"
        let steps = "Test steps"
        let expected = "Test expected"
        let actual = "Test actual"
        let diagnostics = "App Version: 2.0.0 (200)"

        let report = BugReportPreflightScreenViewModel.buildReport(summary: summary,
                                                                   stepsToReproduce: steps,
                                                                   expectedResult: expected,
                                                                   actualResult: actual,
                                                                   diagnosticsText: diagnostics)

        XCTAssertTrue(report.contains("## Summary"))
        XCTAssertTrue(report.contains("## Steps to Reproduce"))
        XCTAssertTrue(report.contains("## Expected Result"))
        XCTAssertTrue(report.contains("## Actual Result"))
        XCTAssertTrue(report.contains("## Diagnostics"))
        XCTAssertTrue(report.contains(summary))
        XCTAssertTrue(report.contains(steps))
        XCTAssertTrue(report.contains(expected))
        XCTAssertTrue(report.contains(actual))
    }

    func testBuildReportRedactsDiagnostics() {
        let summary = "Bug"
        let steps = "Steps"
        let expected = "Expected"
        let actual = "Actual"
        let diagnostics = "User: @alice:matrix.org\nEmail: alice@example.com\nURL: https://element.io"

        let report = BugReportPreflightScreenViewModel.buildReport(summary: summary,
                                                                   stepsToReproduce: steps,
                                                                   expectedResult: expected,
                                                                   actualResult: actual,
                                                                   diagnosticsText: diagnostics)

        XCTAssertFalse(report.contains("@alice:matrix.org"))
        XCTAssertFalse(report.contains("alice@example.com"))
        XCTAssertFalse(report.contains("https://element.io"))
        XCTAssertTrue(report.contains("<redacted-matrix-id>"))
        XCTAssertTrue(report.contains("<redacted-email>"))
        XCTAssertTrue(report.contains("<redacted-url>"))
    }

    func testBuildReportWithNilDiagnostics() {
        let report = BugReportPreflightScreenViewModel.buildReport(summary: "S",
                                                                   stepsToReproduce: "St",
                                                                   expectedResult: "E",
                                                                   actualResult: "A",
                                                                   diagnosticsText: nil)

        XCTAssertFalse(report.contains("## Diagnostics"))
        XCTAssertTrue(report.contains("## Summary"))
    }
}
