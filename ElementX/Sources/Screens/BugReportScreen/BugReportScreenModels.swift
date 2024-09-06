//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import UIKit

enum BugReportScreenViewModelAction {
    case cancel
    case viewLogs
    case submitStarted(progressPublisher: CurrentValuePublisher<Double, Never>)
    case submitFinished
    case submitFailed(error: Error)
}

struct BugReportScreenViewState: BindableState {
    var screenshot: UIImage?
    var bindings: BugReportScreenViewStateBindings
    let isModallyPresented: Bool
    var shouldDisableInteraction = false
}

struct BugReportScreenViewStateBindings {
    var reportText: String
    var sendingLogsEnabled: Bool
    var canContact: Bool
}

enum BugReportScreenViewAction {
    case cancel
    case submit
    case removeScreenshot
    case attachScreenshot(UIImage)
    case viewLogs
}
