//
//  BuildSettings.swift
//  ElementX
//
//  Created by Ismail on 2.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation

final class BuildSettings {

    // MARK: - Bug report
    static let bugReportServiceBaseUrlString = "https://riot.im/bugreports"
    static let bugReportSentryEndpoint = "https://f39ac49e97714316965b777d9f3d6cd8@sentry.tools.element.io/44"
    // Use the name allocated by the bug report server
    static let bugReportApplicationId = "riot-ios"
    static let bugReportUISIId = "element-auto-uisi"

    static let bugReportGHLabels: [String] = ["Element-X"]

    // MARK: - Settings screen
    static let settingsCrashButtonVisible: Bool = true
    static let settingsShowTimelineStyle: Bool = true

    // MARK: - Room screen
    static let defaultRoomTimelineStyle: TimelineStyle = .bubbled

}
