//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

final class MockCoder: NSKeyedArchiver {
    deinit {
        finishEncoding()
    }
    
    override func decodeObject(forKey _: String) -> Any { "" }
    override func decodeInt64(forKey key: String) -> Int64 { 0 }
}
