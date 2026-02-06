//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// MARK: - Interfaces

protocol BugReportPreflightReportBuilding {
    func buildReport(summary: String, steps: String, expected: String, actual: String, diagnostics: String) -> String
}

// MARK: - Implementations

final class BugReportPreflightReportBuilder: BugReportPreflightReportBuilding {
    // MARK: - Public Methods

    func buildReport(summary: String, steps: String, expected: String, actual: String, diagnostics: String) -> String {
        [
            "Summary:\n\(summary.trimmingCharacters(in: .whitespacesAndNewlines))",
            "Steps:\n\(steps.trimmingCharacters(in: .whitespacesAndNewlines))",
            "Expected:\n\(expected.trimmingCharacters(in: .whitespacesAndNewlines))",
            "Actual:\n\(actual.trimmingCharacters(in: .whitespacesAndNewlines))",
            "Diagnostics:\n\(diagnostics.trimmingCharacters(in: .whitespacesAndNewlines))"
        ].joined(separator: "\n\n")
    }
}
