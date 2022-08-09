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

final class BuildSettings {
    // MARK: - Servers

    static let defaultHomeserverAddress = "matrix.org"

    // MARK: - Bug report

    static let bugReportServiceBaseUrlString = "https://riot.im/bugreports"
    static let bugReportSentryEndpoint = "https://f39ac49e97714316965b777d9f3d6cd8@sentry.tools.element.io/44"
    // Use the name allocated by the bug report server
    static let bugReportApplicationId = "riot-ios"
    static let bugReportUISIId = "element-auto-uisi"

    static let bugReportGHLabels = ["Element-X"]

    // MARK: - Settings screen

    static let settingsCrashButtonVisible = true
    static let settingsShowTimelineStyle = true

    // MARK: - Room screen

    static let defaultRoomTimelineStyle: TimelineStyle = .bubbles
}
