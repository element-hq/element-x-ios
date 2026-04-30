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
/// item) or to the read marker (NEW banner). Optionally displays a count badge.
struct TimelineScrollButton: View {
    enum Direction {
        case down
        case up
    }

    let direction: Direction
    let isHidden: Bool
    let badgeCount: Int
    let callback: () -> Void

    @ScaledMetric(relativeTo: .compound.bodyLG) private var iconSize: CGFloat = 14
    @ScaledMetric(relativeTo: .compound.bodyLG) private var badgeSize: CGFloat = 20
    @ScaledMetric(relativeTo: .compound.bodyLG) private var badgeDotSize: CGFloat = 14
    @ScaledMetric(relativeTo: .compound.bodyLG) private var badgeOffsetY: CGFloat = -10

    init(direction: Direction = .down,
         isHidden: Bool = false,
         badgeCount: Int = 0,
         callback: @escaping () -> Void) {
        self.direction = direction
        self.isHidden = isHidden
        self.badgeCount = badgeCount
        self.callback = callback
    }

    var body: some View {
        Button { callback() } label: {
            ZStack(alignment: .top) {
                icon
                if badgeCount > 0 {
                    badge
                        .offset(y: badgeOffsetY)
                }
            }
            .padding()
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
            .padding(13)
            .offset(y: direction == .down ? 1 : -1)
            .background {
                Circle()
                    .fill(Color.compound.iconOnSolidPrimary)
                    // Intentionally using system primary colour to get white/black.
                    .shadow(color: .primary.opacity(0.33), radius: 2.0)
            }
    }

    @ViewBuilder
    private var badge: some View {
        if badgeCount > 9 {
            // For two-digit-plus counts, fall back to a small dot so the badge stays compact.
            Circle()
                .fill(Color.compound.bgBadgeAccent)
                .frame(width: badgeDotSize, height: badgeDotSize)
                .overlay(Circle().stroke(Color.compound.iconOnSolidPrimary, lineWidth: 2))
        } else {
            Text("\(badgeCount)")
                .font(.compound.bodyXSSemibold)
                .foregroundColor(.compound.textBadgeAccent)
                .frame(width: badgeSize, height: badgeSize)
                .background {
                    Circle()
                        .fill(Color.compound.bgBadgeAccent)
                        .overlay(Circle().stroke(Color.compound.iconOnSolidPrimary, lineWidth: 2))
                }
        }
    }
}

struct TimelineScrollButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 16) {
            TimelineScrollButton(direction: .down) { }
            TimelineScrollButton(direction: .down, badgeCount: 3) { }
            TimelineScrollButton(direction: .down, badgeCount: 42) { }
            TimelineScrollButton(direction: .up, badgeCount: 7) { }
            TimelineScrollButton(direction: .up, isHidden: true, badgeCount: 7) { }
        }
        .padding()
        .background(Color.compound.bgCanvasDefault)
        .previewLayout(.sizeThatFits)
    }
}
