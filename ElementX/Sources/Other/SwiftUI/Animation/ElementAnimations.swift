//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import SwiftUI

public extension Animation {
    /// Animation to be used to disable animations.
    static let noAnimation: Animation = .linear(duration: 0)

    /// `noAnimation` if running tests, otherwise `default` animation if `UIAccessibility.isReduceMotionEnabled` is false
    static var elementDefault: Animation {
        let animation: Animation = Tests.isRunningTests ? .noAnimation : .default
        return animation.disabledIfReduceMotionEnabled()
    }

    // `noAnimation` if running tests, otherwise `self` if `UIAccessibility.isReduceMotionEnabled` is false
    func disabledDuringTests() -> Self {
        let animation: Animation = Tests.isRunningTests ? .noAnimation : self
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
public func withElementAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
    try withAnimation(animation?.disabledDuringTests(), body)
}
