//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

protocol CompoundHookProtocol {
    @MainActor func override(colors: CompoundColors, uiColors: CompoundUIColors)
}

struct DefaultCompoundHook: CompoundHookProtocol {
    // MARK: - UCMeet.Chat Navy Blue Palette

    // Navy 900 (primary accent)
    private static let navy900 = Color(red: 0.0, green: 0.231, blue: 0.365)
    private static let navy900UI = UIColor(red: 0.0, green: 0.231, blue: 0.365, alpha: 1.0)
    // Navy 1000 (hover)
    private static let navy1000 = Color(red: 0.0, green: 0.180, blue: 0.286)
    private static let navy1000UI = UIColor(red: 0.0, green: 0.180, blue: 0.286, alpha: 1.0)
    // Navy 1100 (pressed)
    private static let navy1100 = Color(red: 0.0, green: 0.133, blue: 0.212)
    private static let navy1100UI = UIColor(red: 0.0, green: 0.133, blue: 0.212, alpha: 1.0)
    // Navy 800 (secondary)
    private static let navy800 = Color(red: 0.102, green: 0.333, blue: 0.471)
    private static let navy800UI = UIColor(red: 0.102, green: 0.333, blue: 0.471, alpha: 1.0)
    // Navy 700 (subtle)
    private static let navy700 = Color(red: 0.200, green: 0.435, blue: 0.576)
    private static let navy700UI = UIColor(red: 0.200, green: 0.435, blue: 0.576, alpha: 1.0)

    func override(colors: CompoundColors, uiColors: CompoundUIColors) {
        // MARK: SwiftUI Color overrides

        // Accent backgrounds
        colors.override(\.bgAccentRest, with: Self.navy900)
        colors.override(\.bgAccentHovered, with: Self.navy1000)
        colors.override(\.bgAccentPressed, with: Self.navy1100)
        colors.override(\.bgAccentSelected, with: Self.navy900.opacity(0.20))

        // Icons
        colors.override(\.iconAccentPrimary, with: Self.navy900)
        colors.override(\.iconAccentTertiary, with: Self.navy800)

        // Text
        colors.override(\.textActionAccent, with: Self.navy900)
        colors.override(\.textBadgeAccent, with: Self.navy1100)

        // Borders
        colors.override(\.borderAccentSubtle, with: Self.navy700)

        // Badges
        colors.override(\.bgBadgeAccent, with: Self.navy900.opacity(0.23))

        // Success tokens (upstream uses green for both accent and success)
        colors.override(\.iconSuccessPrimary, with: Self.navy900)
        colors.override(\.textSuccessPrimary, with: Self.navy900)
        colors.override(\.bgSuccessSubtle, with: Self.navy900.opacity(0.10))
        colors.override(\.borderSuccessSubtle, with: Self.navy700)

        // Action gradient (send button)
        colors.override(\.gradientActionStop1, with: Self.navy800)
        colors.override(\.gradientActionStop2, with: Self.navy900)
        colors.override(\.gradientActionStop3, with: Self.navy1000)
        colors.override(\.gradientActionStop4, with: Self.navy1100)

        // Gradient stops (home screen gradient)
        colors.override(\.gradientSubtleStop1, with: Self.navy900.opacity(0.33))
        colors.override(\.gradientSubtleStop2, with: Self.navy900.opacity(0.27))
        colors.override(\.gradientSubtleStop3, with: Self.navy900.opacity(0.20))
        colors.override(\.gradientSubtleStop4, with: Self.navy900.opacity(0.13))
        colors.override(\.gradientSubtleStop5, with: Self.navy900.opacity(0.07))

        // MARK: UIKit UIColor overrides

        uiColors.override(\.bgAccentRest, with: Self.navy900UI)
        uiColors.override(\.bgAccentHovered, with: Self.navy1000UI)
        uiColors.override(\.bgAccentPressed, with: Self.navy1100UI)
        uiColors.override(\.bgAccentSelected, with: Self.navy900UI.withAlphaComponent(0.20))
        uiColors.override(\.iconAccentPrimary, with: Self.navy900UI)
        uiColors.override(\.iconAccentTertiary, with: Self.navy800UI)
        uiColors.override(\.textActionAccent, with: Self.navy900UI)
        uiColors.override(\.textBadgeAccent, with: Self.navy1100UI)
        uiColors.override(\.borderAccentSubtle, with: Self.navy700UI)
        uiColors.override(\.bgBadgeAccent, with: Self.navy900UI.withAlphaComponent(0.23))
        uiColors.override(\.iconSuccessPrimary, with: Self.navy900UI)
        uiColors.override(\.textSuccessPrimary, with: Self.navy900UI)
        uiColors.override(\.bgSuccessSubtle, with: Self.navy900UI.withAlphaComponent(0.10))
        uiColors.override(\.borderSuccessSubtle, with: Self.navy700UI)
        uiColors.override(\.gradientActionStop1, with: Self.navy800UI)
        uiColors.override(\.gradientActionStop2, with: Self.navy900UI)
        uiColors.override(\.gradientActionStop3, with: Self.navy1000UI)
        uiColors.override(\.gradientActionStop4, with: Self.navy1100UI)
        uiColors.override(\.gradientSubtleStop1, with: Self.navy900UI.withAlphaComponent(0.33))
        uiColors.override(\.gradientSubtleStop2, with: Self.navy900UI.withAlphaComponent(0.27))
        uiColors.override(\.gradientSubtleStop3, with: Self.navy900UI.withAlphaComponent(0.20))
        uiColors.override(\.gradientSubtleStop4, with: Self.navy900UI.withAlphaComponent(0.13))
        uiColors.override(\.gradientSubtleStop5, with: Self.navy900UI.withAlphaComponent(0.07))
    }
}
