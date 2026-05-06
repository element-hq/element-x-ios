//
// Copyright 2026 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A small floating circular button used by the timeline to jump to either the bottom (newest
/// item) or to the read marker (NEW banner). Optionally displays a presence dot.
struct TimelineScrollButton: View {
    enum Direction {
        case down
        case up
    }

    let direction: Direction
    let isHidden: Bool
    let showsBadge: Bool
    let callback: () -> Void

    @ScaledMetric(relativeTo: .compound.bodyLG) private var iconSize: CGFloat = 22
    @ScaledMetric(relativeTo: .compound.bodyLG) private var badgeDotSize: CGFloat = 14
    @ScaledMetric(relativeTo: .compound.bodyLG) private var badgeOffsetY: CGFloat = -10

    /// Padding around the chevron, balanced so the total circle stays ~40pt at default text size.
    private let iconPadding: CGFloat = 9

    init(direction: Direction = .down,
         isHidden: Bool = false,
         showsBadge: Bool = false,
         callback: @escaping () -> Void) {
        self.direction = direction
        self.isHidden = isHidden
        self.showsBadge = showsBadge
        self.callback = callback
    }

    var body: some View {
        Button { callback() } label: {
            ZStack(alignment: .top) {
                icon
                if showsBadge {
                    badge
                        .offset(y: badgeOffsetY)
                }
            }
        }
        .opacity(isHidden ? 0 : 1)
        .allowsHitTesting(!isHidden)
        .accessibilityHidden(isHidden)
        .accessibilityLabel(direction == .down ? L10n.a11yJumpToBottom : UntranslatedL10n.a11yJumpToUnread)
        .animation(.elementDefault, value: isHidden)
    }

    private var icon: some View {
        CompoundIcon(direction == .down ? \.chevronDown : \.chevronUp,
                     size: .custom(iconSize),
                     relativeTo: .compound.bodyLG)
            .foregroundColor(.compound.iconSecondary)
            .padding(iconPadding)
            .background {
                Circle()
                    .fill(Color.compound.iconOnSolidPrimary)
                    // Intentionally using system primary colour to get white/black.
                    .shadow(color: .primary.opacity(0.33), radius: 2.0)
            }
    }

    private var badge: some View {
        Circle()
            .fill(Color.compound.iconAccentTertiary)
            .frame(width: badgeDotSize, height: badgeDotSize)
            .overlay(Circle().stroke(Color.compound.iconOnSolidPrimary, lineWidth: 2))
    }
}

struct TimelineScrollButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 16) {
            TimelineScrollButton(direction: .down) { }
            TimelineScrollButton(direction: .down, showsBadge: true) { }
            TimelineScrollButton(direction: .up) { }
            TimelineScrollButton(direction: .up, showsBadge: true) { }
            TimelineScrollButton(direction: .up, isHidden: true, showsBadge: true) { }
        }
        .padding()
        .background(Color.compound.bgCanvasDefault)
        .previewLayout(.sizeThatFits)
    }
}
