//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@testable import Compound
import SwiftUI
import XCTest

final class DecorativeColorsTests: XCTestCase {
    struct TestCase {
        let input: String
        private let webOutput: Int
        
        // remember that web starts the index from 1 while we start from 0
        var output: Int {
            webOutput - 1
        }
        
        init(input: String, webOutput: Int) {
            self.input = input
            self.webOutput = webOutput
        }
    }
    
    func testAvatarColorHash() {
        // Match the tests with the web ones for consistency between the two platforms
        // https://github.com/element-hq/compound-web/blob/4608dc807c9c904874eac67ff22be3213f4a261d/src/components/Avatar/Avatar.test.tsx#L62
        let testCases: [TestCase] = [
            .init(input: "@bob:example.org", webOutput: 4),
            .init(input: "@alice:example.org", webOutput: 3),
            .init(input: "@charlie:example.org", webOutput: 5),
            .init(input: "@dan:example.org", webOutput: 4),
            .init(input: "@elena:example.org", webOutput: 4),
            .init(input: "@fanny:example.org", webOutput: 3)
        ]
        
        for testCase in testCases {
            XCTAssertEqual(Color.compound.decorativeColor(for: testCase.input), Color.compound.decorativeColors[testCase.output])
        }
    }
}
