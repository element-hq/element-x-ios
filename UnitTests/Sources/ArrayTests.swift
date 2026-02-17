//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

@Suite
struct ArrayTests {
    @Test
    func grouping() {
        #expect([].groupBy { $0 == 0 } == [])
        
        #expect([0].groupBy { $0 == 0 } == [[0]])
        
        #expect([1].groupBy { $0 == 0 } == [[1]])
        
        #expect([0, 0, 0].groupBy { $0 == 0 } == [[0, 0, 0]])
        
        #expect([1, 1, 1].groupBy { $0 == 0 } == [[1], [1], [1]])
        
        #expect([1, 0, 0, 1].groupBy { $0 == 0 } == [[1], [0, 0], [1]])
        
        #expect([0, 0, 1, 0].groupBy { $0 == 0 } == [[0, 0], [1], [0]])
        
        #expect([0, 0, 0, 1, 2, 3, 0].groupBy { $0 == 0 } == [[0, 0, 0], [1], [2], [3], [0]])
        
        #expect([0, 0, 0, 1, 2, 3, 0, 0].groupBy { $0 == 0 } == [[0, 0, 0], [1], [2], [3], [0, 0]])
        
        #expect([0, 0, 0, 1, 0, 2, 3, 0, 0].groupBy { $0 == 0 } == [[0, 0, 0], [1], [0], [2], [3], [0, 0]])
    }
}
