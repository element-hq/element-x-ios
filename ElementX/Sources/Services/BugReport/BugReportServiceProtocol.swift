//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import UIKit

struct BugReport: Equatable {
    let userID: String
    let deviceID: String?
    let text: String
    let includeLogs: Bool
    let includeCrashLog: Bool
    let githubLabels: [String]
    let files: [URL]
}

struct SubmitBugReportResponse: Decodable {
    var reportUrl: String
}

enum BugReportServiceError: LocalizedError {
    case uploadFailure(Error)
    case serverError(URLResponse, String)
    case httpError(HTTPURLResponse, String)
    
    var errorDescription: String? {
        switch self {
        case .uploadFailure(let error):
            return error.localizedDescription
        case .serverError(_, let errorDescription):
            return errorDescription
        case .httpError(_, let errorDescription):
            return errorDescription
        }
    }
}

// sourcery: AutoMockable
protocol BugReportServiceProtocol {
    var isRunning: Bool { get }
    
    var crashedLastRun: Bool { get }
    
    func start()
           
    func stop()
    
    func reset()

    func crash()
    
    func submitBugReport(_ bugReport: BugReport,
                         progressListener: ProgressListener?) async -> Result<SubmitBugReportResponse, BugReportServiceError>
}
