//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// sourcery: AutoMockable
protocol NotificationToneManagerProtocol {
    func setSelectedTone(_ alertTone: NotificationAlertTone)
    func customTones() -> [NotificationAlertTone]
    @NotificationToneManager.ConversionActor
    @discardableResult
    func addNewToneToLibrary(from sourceURL: URL) throws -> URL
    func deleteCustomTone(_ alertTone: NotificationAlertTone) throws
}
