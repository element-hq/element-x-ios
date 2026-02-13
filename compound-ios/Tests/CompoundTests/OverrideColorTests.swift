//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import Compound
import Foundation
import XCTest

final class OverrideColorTests: XCTestCase {
    /// For some very weird reason we need this to be async, `@MainActoe` won't work
    /// or it will crash.
    /// The other solution would be to make CompoundColors nonisolated
    /// But we don't really need that
    func testSwiftUI() async {
        await MainActor.run {
            let colors = CompoundColors()
            let tokens = CompoundColorTokens()
            XCTAssertEqual(colors.textPrimary, tokens.textPrimary)
            
            colors.override(\.textPrimary, with: .pink)
            XCTAssertEqual(colors.textPrimary, .pink)
            
            colors.override(\.textPrimary, with: nil)
            XCTAssertEqual(colors.textPrimary, tokens.textPrimary)
        }
    }
    
    /// UIColors are nonisolated, so this is fine.
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
