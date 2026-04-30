//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

struct NotificationToneManager {
    private let appSettings: AppSettings
    private let userIndicatorController: UserIndicatorControllerProtocol

    init(appSettings: AppSettings, userIndicatorController: UserIndicatorControllerProtocol) throws {
        self.appSettings = appSettings
        self.userIndicatorController = userIndicatorController

        try FileManager.default.createDirectory(at: NotificationAlertTone.libraryLocation, withIntermediateDirectories: true)
        try FileManager.default.createDirectory(at: NotificationAlertTone.selectedToneLocation.deletingLastPathComponent(), withIntermediateDirectories: true)
    }

    func setSelectedTone(_ alertTone: NotificationAlertTone) {
        do {
            try? FileManager.default.removeItem(at: NotificationAlertTone.selectedToneLocation)
            try FileManager.default.copyItem(at: alertTone.location, to: NotificationAlertTone.selectedToneLocation)
            appSettings.selectedNotificationTone = alertTone
        } catch {
            let userIndicator = UserIndicator(type: .toast,
                                              title: UntranslatedL10n.screenNotificationSettingsConfigurationAlertToneSetToneErrorTitle,
                                              iconName: "exclamationmark.triangle.fill")
            userIndicatorController.submitIndicator(userIndicator)
            MXLog.error("Error setting selected alert tone to designated location in filesystem: \(error)")
        }
    }
}
