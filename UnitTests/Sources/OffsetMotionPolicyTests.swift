//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

struct OffsetMotionPolicyTests {
    @Test(arguments: Release.sliding)
    func travelBetweenHalfAPointAndTheViewportHeightIsSystemAnimated(_ release: Release) {
        #expect(OffsetMotionPolicy.motion(for: release.input()) == .systemAnimated)
    }
    
    @Test(arguments: Release.tooFar)
    func travelBiggerThanTheViewportSnaps(_ release: Release) {
        #expect(OffsetMotionPolicy.motion(for: release.input()) == .snap)
    }
    
    @Test(arguments: Release.tooShort)
    func noTravelSnaps(_ release: Release) {
        #expect(OffsetMotionPolicy.motion(for: release.input()) == .snap)
    }
    
    @Test(arguments: Release.all)
    func reduceMotionAndVoiceOverSnapWhateverTheTravel(_ release: Release) {
        #expect(OffsetMotionPolicy.motion(for: release.input(reduceMotion: true)) == .snap)
        #expect(OffsetMotionPolicy.motion(for: release.input(isVoiceOverRunning: true)) == .snap)
        #expect(OffsetMotionPolicy.motion(for: release.input(reduceMotion: true, isVoiceOverRunning: true)) == .snap)
    }
    
    // MARK: - Releases
    
    /// A release of `travel` points in a viewport of `viewportHeight` points.
    nonisolated struct Release: CustomTestStringConvertible {
        /// A phone and an iPad.
        private static let viewportHeights: [CGFloat] = [600, 1000]
        
        /// 44 points is about a single-line send and 0.5 the smallest move worth animating.
        static let sliding = releases { [0.5, 1, 44, 120, $0 * 0.8, $0] }
        static let tooFar = releases { [$0 + 1, $0 * 2] }
        static let tooShort = releases { _ in [0, 0.2, 0.49] }
        static let all = sliding + tooFar + tooShort
        
        let travel: CGFloat
        let viewportHeight: CGFloat
        
        var testDescription: String {
            "\(travel) points in \(viewportHeight)"
        }
        
        func input(reduceMotion: Bool = false, isVoiceOverRunning: Bool = false) -> OffsetMotionPolicy.Input {
            .init(travel: travel, viewportHeight: viewportHeight, reduceMotion: reduceMotion, isVoiceOverRunning: isVoiceOverRunning)
        }
        
        /// Each distance both ways: the travel is negative whenever the offset sits below the resting bottom.
        private static func releases(_ distances: (CGFloat) -> [CGFloat]) -> [Release] {
            viewportHeights.flatMap { viewportHeight in
                distances(viewportHeight).flatMap { [$0, -$0] }.map { Release(travel: $0, viewportHeight: viewportHeight) }
            }
        }
    }
}
