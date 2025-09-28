//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@testable import Compound
import XCTest

class OverrideColorTests: XCTestCase {
    func testSwiftUI() {
        let colors = CompoundColors()
        let tokens = CompoundColorTokens()
        XCTAssertEqual(colors.textPrimary, tokens.textPrimary)
        
        colors.override(\.textPrimary, with: .pink)
        XCTAssertEqual(colors.textPrimary, .pink)
        
        colors.override(\.textPrimary, with: nil)
        XCTAssertEqual(colors.textPrimary, tokens.textPrimary)
    }
    
    func testUIKit() {
        let colors = CompoundUIColors()
        let tokens = CompoundUIColorTokens()
        XCTAssertEqual(colors.textPrimary, tokens.textPrimary)
        
        colors.override(\.textPrimary, with: .systemPink)
        XCTAssertEqual(colors.textPrimary, .systemPink)
        
        colors.override(\.textPrimary, with: nil)
        XCTAssertEqual(colors.textPrimary, tokens.textPrimary)
    }
}
