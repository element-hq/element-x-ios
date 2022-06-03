//
//  BugReportServiceProtocol.swift
//  ElementX
//
//  Created by Ismail on 16.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation
import UIKit

struct SubmitBugReportResponse: Decodable {
    var reportUrl: String
}

protocol BugReportServiceProtocol {

    var crashedLastRun: Bool { get }

    func crash()

    func submitBugReport(text: String,
                         includeLogs: Bool,
                         includeCrashLog: Bool,
                         githubLabels: [String],
                         files: [URL]) async throws -> SubmitBugReportResponse
}
