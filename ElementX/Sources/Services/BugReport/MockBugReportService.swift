//
//  MockBugReportService.swift
//  ElementX
//
//  Created by Ismail on 16.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation
import UIKit

class MockBugReportService: BugReportServiceProtocol {

    func submitBugReport(text: String,
                         includeLogs: Bool,
                         includeCrashLog: Bool,
                         githubLabels: [String],
                         files: [URL]) async throws -> SubmitBugReportResponse {
        SubmitBugReportResponse(reportUrl: "https://www.example/com/123")
    }

    var crashedLastRun = false

    func crash() {
        // no-op
    }

}
