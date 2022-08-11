//
//  ElementAnimations.swift
//  ElementX
//
//  Created by Ismail on 8.07.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import Foundation
import SwiftUI

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
public extension Animation {
    /// Animation to be used to disable animations.
    static let noAnimation: Animation = .linear(duration: 0)

    /// `noAnimation` if running UI tests, otherwise `default` animation.
    static var elementDefault: Animation {
        Tests.isRunningUITests ? .noAnimation : .default
    }
}

@available(iOS 13.0, macOS 10.15, tvOS 13.0, watchOS 6.0, *)
/// Returns the result of recomputing the view's body with the provided
/// animation.
/// - Parameters:
///   - animation: Animation
///   - body: operations to be animated
public func withElementAnimation<Result>(_ animation: Animation? = .default, _ body: () throws -> Result) rethrows -> Result {
    if Tests.isRunningUITests {
        return try withAnimation(.noAnimation, body)
    }
    return try withAnimation(animation, body)
}
