//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import CoreLocation
import QuartzCore

/// Smoothly animates a `LocationAnnotation`'s coordinate from its current
/// position to a new one using a `CADisplayLink` for frame-accurate updates.
///
/// ## How it works
///
/// MapLibre repositions annotation views whenever it observes a KVO change on
/// the annotation's `coordinate` property (which must be `@objc dynamic`).
/// Rather than setting the destination coordinate in one step— which would
/// cause the pin to jump — we interpolate between the start and end coordinates
/// over a configurable duration, updating the coordinate on every display frame.
/// Because MapLibre handles the actual view positioning through KVO, the
/// annotation moves correctly even while the user pans or zooms the map,
/// and even if the annotation is currently off-screen.
///
/// Only one animation runs per annotation at a time; starting a new animation
/// cancels the previous one and begins from the annotation's current position.
final class CoordinateAnimator {
    private var displayLink: CADisplayLink?
    private weak var annotation: LocationAnnotation?
    private let startCoordinate: CLLocationCoordinate2D
    private let endCoordinate: CLLocationCoordinate2D
    private let duration: CFTimeInterval
    private var startTime: CFTimeInterval?
    
    /// Keeps a strong reference to each active animator so it isn't deallocated
    /// while the display link is running. Keyed by annotation ID.
    private static var activeAnimators: [String: CoordinateAnimator] = [:]
    
    private init(annotation: LocationAnnotation,
                 to end: CLLocationCoordinate2D,
                 duration: CFTimeInterval) {
        self.annotation = annotation
        startCoordinate = annotation.coordinate
        endCoordinate = end
        self.duration = duration
    }
    
    /// Starts animating the annotation's coordinate to `end` over `duration` seconds.
    /// If the annotation is already being animated, the in-flight animation is
    /// cancelled and a new one starts from the current position.
    static func animate(annotation: LocationAnnotation,
                        to end: CLLocationCoordinate2D,
                        duration: CFTimeInterval) {
        guard annotation.coordinate.latitude != end.latitude
            || annotation.coordinate.longitude != end.longitude else {
            return
        }
        
        // Cancel any in-flight animation for this annotation
        activeAnimators[annotation.id]?.stop()
        
        let animator = CoordinateAnimator(annotation: annotation, to: end, duration: duration)
        activeAnimators[annotation.id] = animator
        animator.start()
    }
    
    // MARK: - Private
    
    private func start() {
        let displayLink = CADisplayLink(target: self, selector: #selector(tick))
        // Using .common so the animation keeps running during scroll tracking
        displayLink.add(to: .main, forMode: .common)
        self.displayLink = displayLink
    }
    
    private func stop() {
        displayLink?.invalidate()
        displayLink = nil
        if let annotation {
            Self.activeAnimators.removeValue(forKey: annotation.id)
        }
    }
    
    /// Called on every display frame. Linearly interpolates between the start
    /// and end coordinates using an ease-in-out curve, then updates the
    /// annotation's coordinate to trigger MapLibre's KVO repositioning.
    @objc private func tick(_ displayLink: CADisplayLink) {
        guard let annotation else {
            stop()
            return
        }
        
        if startTime == nil {
            startTime = displayLink.timestamp
        }
        
        let elapsed = displayLink.timestamp - (startTime ?? displayLink.timestamp)
        let linearProgress = min(elapsed / duration, 1.0)
        let easedProgress = quadraticEaseInOut(linearProgress)
        
        let latitude = startCoordinate.latitude + (endCoordinate.latitude - startCoordinate.latitude) * easedProgress
        let longitude = startCoordinate.longitude + (endCoordinate.longitude - startCoordinate.longitude) * easedProgress
        annotation.coordinate = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        
        if linearProgress >= 1.0 {
            stop()
        }
    }
    
    /// Quadratic ease-in-out: accelerates during the first half, decelerates
    /// during the second half.
    ///
    /// - Parameter t: Linear progress in the range `0...1`.
    /// - Returns: Eased progress in the range `0...1`.
    private func quadraticEaseInOut(_ t: Double) -> Double {
        if t < 0.5 {
            // Ease-in: parabolic acceleration from 0 to the midpoint
            return 2 * t * t
        } else {
            // Ease-out: parabolic deceleration from the midpoint to 1
            // Equivalent to: 1 - 2 * (1 - t)^2
            let shifted = t - 1
            return 1 - 2 * shifted * shifted
        }
    }
}
