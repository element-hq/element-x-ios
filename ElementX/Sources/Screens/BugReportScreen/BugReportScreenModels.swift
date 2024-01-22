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
