//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension BugReportServiceMock {
    struct Configuration { }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        lastCrashEventIDSubject = .init(nil)
        submitBugReportFlowProgressListenerReturnValue = .success(SubmitBugReportResponse(reportURL: "https://example.com/123"))
    }
}
