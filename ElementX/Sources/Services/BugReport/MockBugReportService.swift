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

    init(withApplicationId applicationId: String = "mock_app_id") {
        self.applicationId = applicationId
    }

    var applicationId: String

    func submitBugReport(text: String,
                         includeLogs: Bool,
                         includeCrashLog: Bool,
                         githubLabels: [String],
                         files: [URL]) async throws -> SubmitBugReportResponse {
        return SubmitBugReportResponse(reportUrl: "https://www.example/com/123")
    }

    var applicationWasCrashed: Bool = false

    func crash() {
        
    }

}
