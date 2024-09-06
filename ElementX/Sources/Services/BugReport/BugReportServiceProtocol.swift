//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import UIKit

struct BugReport: Equatable {
    let userID: String?
    let deviceID: String?
    let ed25519: String?
    let curve25519: String?
    let text: String
    let includeLogs: Bool
    let canContact: Bool
    var githubLabels: [String]
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
protocol BugReportServiceProtocol: AnyObject {
    var crashedLastRun: Bool { get }
    
    var lastCrashEventID: String? { get set }
    
    func submitBugReport(_ bugReport: BugReport,
                         progressListener: CurrentValueSubject<Double, Never>) async -> Result<SubmitBugReportResponse, BugReportServiceError>
}
