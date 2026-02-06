//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

final class BugReportPreflightTests: XCTestCase {
    // MARK: - Public Properties

    func testRedactorRedactsSensitiveData() {
        let redactor = Redactor()
        let input = "Email test@example.com URL https://matrix.org ID @alice:matrix.org"
        let redacted = redactor.redact(input)
        XCTAssertEqual(redacted, "Email <redacted> URL <redacted> ID <redacted>")
    }

    func testReportBuilderDeterministicFormat() {
        let builder = BugReportPreflightReportBuilder()
        let report = builder.buildReport(summary: "Summary text",
                                         steps: "Step 1\nStep 2",
                                         expected: "Expected text",
                                         actual: "Actual text",
                                         diagnostics: "Line1\nLine2")
        let expected = [
            ["Summary:\nSummary text", "Steps:\nStep 1\nStep 2", "Expected:\nExpected text", "Actual:\nActual text", "Diagnostics:"]
                .joined(separator: "\n\n"),
            ["Line1", "Line2"]
                .joined(separator: "\n")
        ].joined(separator: "\n")
        XCTAssertEqual(report, expected)
    }
}
