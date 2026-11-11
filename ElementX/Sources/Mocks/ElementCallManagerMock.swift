//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine

extension ElementCallManagerMock {
    struct Configuration {
        var actionsPublisher: AnyPublisher<ElementCallManagerAction, Never> = Empty().eraseToAnyPublisher()
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        actionsPublisher = configuration.actionsPublisher
    }
}
