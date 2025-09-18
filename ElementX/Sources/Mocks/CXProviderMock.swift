//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

extension CXProviderMock {
    struct Configuration { }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        reportNewIncomingCallWithUpdateCompletionClosure = { _, _, completion in
            completion(nil)
        }
    }
}
