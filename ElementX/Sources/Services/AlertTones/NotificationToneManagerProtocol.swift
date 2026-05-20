//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// sourcery: AutoMockable
protocol NotificationToneManagerProtocol {
    @discardableResult
    func setSelectedTone(_ alertTone: NotificationTone) throws -> URL
    func customTones() -> [NotificationTone]
    func deleteCustomTone(_ alertTone: NotificationTone) throws
    
    @NotificationToneManager.ConversionActor
    @discardableResult
    func addNewToneToLibrary(from sourceURL: URL) throws -> URL
}
