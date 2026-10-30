//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// How the send hold's release travels to the bottom. There's deliberately no `UIView.animate` option: animating
/// `contentOffset` that way recycles the cells that aren't visible at the end of the animation straight away,
/// blanking rows mid-move. A release only starts once no drag or fling is running, so there are no gesture inputs.
nonisolated enum OffsetMotionPolicy {
    nonisolated enum Motion: Equatable {
        /// `setContentOffset(_:animated: true)`.
        case systemAnimated
        /// `setContentOffset(_:animated: false)`; stops any deceleration.
        case snap
    }
    
    nonisolated struct Input: Equatable {
        /// How far the offset has to move, in either direction.
        let travel: CGFloat
        /// The visible height the travel is compared with.
        let viewportHeight: CGFloat
        let reduceMotion: Bool
        let isVoiceOverRunning: Bool
    }
    
    static func motion(for input: Input) -> Motion {
        if input.reduceMotion || input.isVoiceOverRunning {
            return .snap
        }
        if abs(input.travel) < 0.5 || abs(input.travel) > input.viewportHeight {
            return .snap
        }
        return .systemAnimated
    }
}
