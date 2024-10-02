//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

public extension Animation {
    /// Animation to be used to disable animations.
    static let noAnimation: Animation = .linear(duration: 0)

    /// `noAnimation` if running tests, otherwise `default` animation if `UIAccessibility.isReduceMotionEnabled` is false
    static var elementDefault: Animation {
        let animation: Animation = ProcessInfo.isRunningTests ? .noAnimation : .default
        return animation.disabledIfReduceMotionEnabled()
    }

    // `noAnimation` if running tests, otherwise `self` if `UIAccessibility.isReduceMotionEnabled` is false
    func disabledDuringTests() -> Self {
        let animation: Animation = ProcessInfo.isRunningTests ? .noAnimation : self
        return animation.disabledIfReduceMotionEnabled()
    }

    // MARK: - Private

    private func disabledIfReduceMotionEnabled() -> Self {
        UIAccessibility.isReduceMotionEnabled ? .noAnimation : self
    }
}

/// Returns the result of recomputing the view's body with the provided
/// animation.
/// - Parameters:
///   - animation: Animation
///   - body: operations to be animated
func withElementAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
    try withAnimation(animation?.disabledDuringTests(), body)
}
