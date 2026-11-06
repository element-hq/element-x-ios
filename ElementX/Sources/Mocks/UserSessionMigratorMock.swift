//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension UserSessionMigratorMock {
    struct Configuration {
        /// The version sessions are marked as migrated to.
        var newVersion = "99.12.31"
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        migrateClosure = { userSession in
            userSession.userSettings.account.lastVersionMigrated = configuration.newVersion
        }
        markAsMigratedClosure = { userSession in
            userSession.userSettings.account.lastVersionMigrated = configuration.newVersion
        }
    }
}
