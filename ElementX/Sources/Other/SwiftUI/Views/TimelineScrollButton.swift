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
    let onLongPress: (() -> Void)?
    let callback: () -> Void

    @ScaledMetric(relativeTo: .compound.bodyLG) private var iconSize: CGFloat = 24
    @ScaledMetric(relativeTo: .compound.bodyLG) private var badgeDotSize: CGFloat = 12
    @GestureState private var isPressing = false
    /// Set when a long-press is recognized so the trailing touch-up doesn't also fire `callback()`.
    @State private var consumedByLongPress = false

    /// Padding around the chevron, balanced so the total circle stays ~36pt at default text size.
    private let iconPadding: CGFloat = 6

    /// Vertical offset that half-centers the badge dot on the circle's edge. Magnitude is half
    /// the dot's diameter so half sits inside the circle, half outside. Sign is applied at the
    /// call site based on direction.
    private var badgeOffsetMagnitude: CGFloat {
        badgeDotSize / 2
    }

    init(direction: Direction = .down,
         isHidden: Bool = false,
         showsBadge: Bool = false,
         onLongPress: (() -> Void)? = nil,
         callback: @escaping () -> Void) {
        self.direction = direction
        self.isHidden = isHidden
        self.showsBadge = showsBadge
        self.onLongPress = onLongPress
        self.callback = callback
    }

    var body: some View {
        if let onLongPress {
            buttonContent
                .scaleEffect(isPressing ? 1.05 : 1.0)
                .compositingGroup()
                .shadow(color: .black.opacity(isPressing ? 0.2 : 0), radius: isPressing ? 12 : 0)
                .animation(.spring(response: 0.7), value: isPressing)
                .simultaneousGesture(LongPressGesture(minimumDuration: 0.5)
                    .updating($isPressing) { current, state, _ in state = current }
                    .onEnded { _ in
                        consumedByLongPress = true
                        UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                        onLongPress()
                        // Safety net: if the user releases off-button after the long-press is
                        // recognized, the Button's tap never fires and won't clear the flag,
                        // which would swallow their next tap. Clear it past the touch-up window.
                        Task { @MainActor in
                            try? await Task.sleep(for: .milliseconds(500))
                            consumedByLongPress = false
                        }
                    })
        } else {
            buttonContent
        }
    }

    private var buttonContent: some View {
        Button {
            if consumedByLongPress {
                consumedByLongPress = false
                return
            }
            callback()
        } label: {
            ZStack(alignment: direction == .down ? .bottom : .top) {
                icon
                if showsBadge {
                    badge
                        .offset(y: direction == .down ? badgeOffsetMagnitude : -badgeOffsetMagnitude)
                }
            }
        }
        .opacity(isHidden ? 0 : 1)
        .allowsHitTesting(!isHidden)
        .accessibilityHidden(isHidden)
        .accessibilityLabel(direction == .down ? L10n.a11yJumpToBottom : UntranslatedL10n.a11yJumpToUnread)
        .animation(.elementDefault, value: isHidden)
    }

    @ViewBuilder
    private var icon: some View {
        let chevron = CompoundIcon(direction == .down ? \.chevronDown : \.chevronUp,
                                   size: .custom(iconSize),
                                   relativeTo: .compound.bodyLG)
            .foregroundStyle(.compound.iconPrimary)
            .padding(iconPadding)
        if #available(iOS 26, *) {
            chevron
                .glassEffect(.regular, in: Circle())
                .overlay(Circle().stroke(Color.compound.borderInteractiveSecondary, lineWidth: 1))
        } else {
            chevron
                .background(.regularMaterial, in: Circle())
                .overlay(Circle().stroke(Color.compound.borderInteractiveSecondary, lineWidth: 1))
        }
    }

    private var badge: some View {
        Circle()
            .fill(Color.compound.iconAccentPrimary)
            .frame(width: badgeDotSize, height: badgeDotSize)
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
