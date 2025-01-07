//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

extension PhotoLibraryManagerMock {
    struct Configuration {
        var authorizationDenied = false
    }
    
    // swiftlint:disable:next cyclomatic_complexity
    convenience init(_ configuration: Configuration) {
        self.init()
        
        addResourceAtReturnValue = configuration.authorizationDenied ? .failure(PhotoLibraryManagerError.notAuthorized) : .success(())
    }
}
