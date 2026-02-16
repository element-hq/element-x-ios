//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import Compound
import Foundation
import Testing

@Suite
struct OverrideColorTests {
    @Test("SwiftUI color override")
    func swiftUI() {
        let colors = CompoundColors()
        let tokens = CompoundColorTokens()
        #expect(colors.textPrimary == tokens.textPrimary)
        
        colors.override(\.textPrimary, with: .pink)
        #expect(colors.textPrimary == .pink)
        
        colors.override(\.textPrimary, with: nil)
        #expect(colors.textPrimary == tokens.textPrimary)
    }
    
    @Test("UIKit color override")
    func uiKit() {
        let colors = CompoundUIColors()
        let tokens = CompoundUIColorTokens()
        #expect(colors.textPrimary == tokens.textPrimary)
        
        colors.override(\.textPrimary, with: .systemPink)
        #expect(colors.textPrimary == .systemPink)
        
        colors.override(\.textPrimary, with: nil)
        #expect(colors.textPrimary == tokens.textPrimary)
    }
}
