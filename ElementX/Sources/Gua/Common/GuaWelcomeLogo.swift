//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreMotion
import SwiftUI

/// The welcome-screen app logo: the Gua app-icon artwork presented as a raised glass tile.
///
/// Comes alive in four ways:
///  - **Entrance** (one-shot, on appear): the logo flies in from the side and spins into place with a
///    spring settle. Pure SwiftUI `@State` — plays on the simulator too. Skipped under Reduce Motion.
///  - **Device-motion angle-of-view** (`CoreMotion`): the logo tilts ±5° in 3D as the phone moves,
///    and a specular highlight sweeps around the two concentric glass-edge lines tracking the tilt
///    direction. Still phone → clean icon, no motion. No gyroscope on simulator (tilt stays at rest
///    there; the entrance still plays).
///  - **Glyph relief** (liquid-glass edges): the wolf and the chat-bubble frame — their own layered
///    assets (`appLogoWolf`, `appLogoBubble`) — carry a thin, *fixed* specular bevel: a light crescent
///    hugs the top edge and a shade crescent the bottom, so both read as raised glass. The bevel
///    geometry never moves — it is baked to a soft overhead light so the whole tile stays one solid
///    object at any tilt (moving the glyph copies is what used to ghost). Only its brightness lifts a
///    touch while the phone is in motion, like light catching real glass.
///  - **Light** (`SwiftUI.TimelineView(.animation)`, display-link backed; `SwiftUI.` qualifier avoids
///    ElementX's own `TimelineView`): an occasional diagonal sheen sweep across the glass (~1s every
///    ~11s) and a steady Gua-green aura behind the tile.
///
/// Static under Reduce Motion (`animated == false`) and in snapshot tests.
struct GuaWelcomeLogo: View {
    /// When `false` (Reduce Motion) the logo is drawn as a still glass tile with no entrance.
    let animated: Bool
    var size: CGFloat = 84

    private let corner: CGFloat = 21
    private var shape: RoundedRectangle {
        RoundedRectangle(cornerRadius: corner, style: .continuous)
    }

    @State private var tilt = DeviceTiltMotion()
    /// Drives the one-shot fly-in/spin entrance: starts off-screen + rotated, springs to rest.
    @State private var entered = false
    /// Set once the entrance spring has been scheduled, so per-frame ticks don't re-arm it.
    @State private var entranceScheduled = false
    /// Time the logo has actually spent on screen (sum of rendered-frame deltas, stall-capped).
    @State private var renderedLeadIn: TimeInterval = 0
    /// Timestamp of the previous rendered frame, for the lead-in accumulation.
    @State private var lastTick: TimeInterval?

    private var isLive: Bool {
        animated && !ProcessInfo.isRunningTests
    }

    /// Off-screen starting offset for the entrance fly-in (the logo arrives from the trailing side).
    private var entranceTravel: CGFloat {
        size * 2.6
    }

    var body: some View {
        Group {
            if isLive {
                SwiftUI.TimelineView(.animation) { context in
                    treated(t: context.date.timeIntervalSinceReferenceDate)
                        .onChange(of: context.date) { startEntranceIfNeeded(now: context.date) }
                }
            } else {
                treated(t: 0)
            }
        }
        .frame(width: size, height: size)
        // One-shot entrance, applied on the OUTER container (independent of the per-frame
        // TimelineView) so it plays exactly once. Unlike the device-motion parallax it needs no
        // gyroscope, so it is fully visible on the simulator too.
        .scaleEffect(entered ? 1 : 0.82)
        .rotation3DEffect(.degrees(entered ? 0 : 68), axis: (x: 0, y: 1, z: 0), perspective: 0.5)
        .offset(x: entered ? 0 : entranceTravel)
        .opacity(entered ? 1 : 0)
        .accessibilityHidden(true)
        .onAppear {
            if isLive {
                tilt.start()
            } else {
                entered = true // Reduce Motion / tests: appear in place, no fly-in.
            }
        }
        .onDisappear { tilt.stop() }
    }

    /// Starts the one-shot entrance after ~0.35s of *rendered* frames rather than from `onAppear`.
    ///
    /// At app launch `onAppear` fires while the launch screen still covers the app and the main
    /// thread is busy starting up, so a wall-clock spring started there burns out before anything
    /// is visible — the logo just pops into place (the "entrance doesn't play" regression). The
    /// `TimelineView` only ticks for frames that are really drawn, so the lead-in is accumulated
    /// from per-frame deltas (capped, so a startup stall can't consume it) and the spring fires
    /// only once the screen has demonstrably been rendering in front of the user for a beat.
    private func startEntranceIfNeeded(now: Date) {
        guard !entranceScheduled else { return }
        let t = now.timeIntervalSinceReferenceDate
        defer { lastTick = t }
        guard let lastTick else { return }
        renderedLeadIn += min(t - lastTick, 1 / 20)
        guard renderedLeadIn >= 0.35 else { return }
        entranceScheduled = true
        withAnimation(.spring(response: 0.52, dampingFraction: 0.66)) {
            entered = true
        }
    }

    private func treated(t: TimeInterval) -> some View {
        logo
            .overlay { glyphRelief() } // raised liquid-glass edges on the wolf + bubble layers
            .overlay { sheen(t: t) }
            .overlay { glassHighlight() }
            .overlay { innerRimLine() } // inner edge line, clipped to icon boundary
            .clipShape(shape)
            .overlay { outerRimLine() } // outer edge line, unclipped — creates the double-line look
            // Slight parallax against the (anchored) aura as the phone tilts — the tile reads as
            // floating above the glow, like the home-screen icon parallax. Zero at rest, so a still
            // phone shows the icon exactly in place.
            .offset(x: tilt.roll * size * 0.025, y: tilt.pitch * size * 0.025)
            .background { aura(t: t) }
            // Whole logo tilts ±5° in 3D — shifting the angle-of-view of the raised glass edges.
            .rotation3DEffect(.degrees(tilt.pitch * 5), axis: (x: 1, y: 0, z: 0), perspective: 0.6)
            .rotation3DEffect(.degrees(tilt.roll * 5), axis: (x: 0, y: 1, z: 0), perspective: 0.6)
            .shadow(color: .black.opacity(0.18), radius: 16, y: 8)
    }

    /// A specular hotspot that slides across the glass as the device tilts — light catching a real
    /// glass surface. Driven purely by `CoreMotion`, so it's still when the phone is still (and
    /// sits centred on the simulator). Clipped to the logo by the caller's `.clipShape`.
    private func glassHighlight() -> some View {
        // Only catches the light while the phone is actually tilting; when still it fades to nothing
        // so it never pools as a bright spot in the centre of the icon.
        let mag = min(1, (tilt.roll * tilt.roll + tilt.pitch * tilt.pitch).squareRoot() * 1.7)
        return RadialGradient(colors: [.white.opacity(0.4), .white.opacity(0.08), .clear],
                              center: .center, startRadius: 0, endRadius: size * 0.55)
            .frame(width: size, height: size)
            .offset(x: tilt.roll * size * 0.32, y: -tilt.pitch * size * 0.32)
            .opacity(mag)
            .blendMode(.screen)
            .allowsHitTesting(false)
    }

    private var logo: some View {
        Image(asset: Asset.Images.appLogo)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
    }

    /// The tilt-driven light-source angle for the rim specular.
    /// At rest (roll=0, pitch=0) the highlight sits at 12 o'clock — natural overhead light.
    private var rimLightAngle: Angle {
        Angle(radians: atan2(tilt.roll, -tilt.pitch) - .pi / 2)
    }

    // MARK: - Glyph liquid-glass bevel

    /// Smoothed tilt magnitude: 0 with the phone still, →1 as it tilts.
    private var tiltMagnitude: Double {
        min(1, (tilt.roll * tilt.roll + tilt.pitch * tilt.pitch).squareRoot())
    }

    /// Fixed overhead light direction for the glyph bevel: straight up (12 o'clock), in screen
    /// coordinates (y down). This is exactly the at-rest value of the old tilt-tracking angle
    /// (`atan2(0, 0.55) - .pi/2`), now frozen so the bevel geometry never translates with tilt —
    /// that translation is what made the wolf and bubble ghost as offset duplicates.
    private var bevelLightVector: CGSize {
        CGSize(width: 0, height: -1)
    }

    /// The specular bevel around the wolf-in-speech-bubble glyph: for each glyph layer
    /// (`appLogoBubble`, then `appLogoWolf`) a thin white crescent hugs the top edge and a dark
    /// crescent the bottom, so the glyph reads as raised glass. The crescents are built by shifting a
    /// tinted copy of the glyph up/down and punching the unshifted glyph back out (`.destinationOut`),
    /// leaving only the exposed edge. The shift is a *fixed* sub-tile bake — it does not track tilt and
    /// the two layers share the same drift (none), so on tilt the whole tile moves as one rigid unit
    /// with no offset duplicate. Only the crescents' brightness lifts a touch while the phone is in
    /// motion, so the glass still catches the light.
    private func glyphRelief() -> some View {
        let mag = tiltMagnitude
        // Fixed bevel depth in points — identical at rest and in motion, so no growing/moving copy.
        let depth = size * 0.014

        return ZStack {
            glyphBevel(asset: Asset.Images.appLogoBubble, depth: depth * 0.85, mag: mag)
            glyphBevel(asset: Asset.Images.appLogoWolf, depth: depth * 1.15, mag: mag)
        }
        .allowsHitTesting(false)
    }

    /// Light + shade crescents for one glyph layer, baked to the fixed overhead light. `mag` only
    /// modulates brightness (the light "catches" more in motion); the crescent geometry is identical
    /// at every tilt so the layer never drifts away from the base artwork.
    private func glyphBevel(asset: ImageAsset, depth: CGFloat, mag: Double) -> some View {
        ZStack {
            // Specular crescent on the lit (top) edge.
            glyphCrescent(asset: asset,
                          color: .white,
                          offset: CGSize(width: bevelLightVector.width * depth, height: bevelLightVector.height * depth))
                .opacity(0.55 + 0.30 * mag)
                .blendMode(.screen)
            // Shade crescent on the far (bottom) edge — sells the raised 3D relief.
            glyphCrescent(asset: asset,
                          color: .black,
                          offset: CGSize(width: -bevelLightVector.width * depth * 0.8, height: -bevelLightVector.height * depth * 0.8))
                .opacity(0.22 + 0.14 * mag)
        }
    }

    /// A thin edge crescent: the glyph tinted `color`, shifted by `offset`, minus the glyph at rest —
    /// only the sliver of the shifted copy that clears the glyph's own silhouette survives.
    private func glyphCrescent(asset: ImageAsset, color: Color, offset: CGSize) -> some View {
        ZStack {
            glyphTemplate(asset, color: color)
                .offset(offset)
            glyphTemplate(asset, color: .black)
                .blendMode(.destinationOut)
        }
        .compositingGroup()
        .blur(radius: size * 0.006)
    }

    private func glyphTemplate(_ asset: ImageAsset, color: Color) -> some View {
        Image(asset: asset)
            .renderingMode(.template)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundStyle(color)
    }

    /// Inner glass-edge line — sits ~2.5 pt inside the clip boundary, with a specular highlight
    /// that tracks the tilt direction. Placed before `.clipShape` so it's bounded by the icon.
    private func innerRimLine() -> some View {
        RoundedRectangle(cornerRadius: corner - 2.5, style: .continuous)
            .stroke(AngularGradient(stops: [
                        .init(color: .white.opacity(0.85), location: 0.00),
                        .init(color: .white.opacity(0.18), location: 0.28),
                        .init(color: .clear, location: 0.50),
                        .init(color: .white.opacity(0.18), location: 0.72),
                        .init(color: .white.opacity(0.85), location: 1.00)
                    ],
                    center: .center,
                    startAngle: rimLightAngle,
                    endAngle: rimLightAngle + .degrees(360)),
                    lineWidth: 1.0)
            .allowsHitTesting(false)
    }

    /// Outer glass-edge line — sits at the clip boundary (placed after `.clipShape`, so it's not
    /// clipped). Together with `innerRimLine` this creates the double-line raised-glass-edge look.
    private func outerRimLine() -> some View {
        shape
            .stroke(AngularGradient(stops: [
                        .init(color: .white.opacity(0.55), location: 0.00),
                        .init(color: .white.opacity(0.07), location: 0.28),
                        .init(color: .clear, location: 0.50),
                        .init(color: .white.opacity(0.07), location: 0.72),
                        .init(color: .white.opacity(0.55), location: 1.00)
                    ],
                    center: .center,
                    startAngle: rimLightAngle,
                    endAngle: rimLightAngle + .degrees(360)),
                    lineWidth: 1.0)
            .allowsHitTesting(false)
    }

    /// A soft white highlight band that sweeps diagonally across the glass (clipped to the logo by
    /// the caller's `.clipShape`). One ~1s pass per ~11s cycle, with a clear idle pause between, so the
    /// sheen reads as an occasional catch of light rather than a constant loop. `.screen` blend makes
    /// it read as light catching the surface.
    private func sheen(t: TimeInterval) -> some View {
        let cycle = 11.0 // total period (glare sweeps less often)
        let sweepDuration = 1.0 // visible travel, then idle for the remainder
        let phase = t.truncatingRemainder(dividingBy: cycle)
        let progress = min(phase / sweepDuration, 1) // 0...1 during the sweep, parked at 1 while idle
        let visible = phase < sweepDuration

        return LinearGradient(colors: [.clear, .white.opacity(0.55), .clear],
                              startPoint: .top, endPoint: .bottom)
            .frame(width: size * 0.42, height: size * 2)
            .rotationEffect(.degrees(35))
            .offset(x: -size * 0.95 + size * 1.9 * progress)
            .opacity(visible ? 1 : 0)
            .blendMode(.screen)
            .allowsHitTesting(false)
    }

    /// A lively Gua-green aura that sits behind the icon and spills ~28% past its edges as a soft
    /// halo. The hue drifts gently around Gua green and the glow slowly shifts position — visible
    /// and alive, but steady (no breathing/pulsing) and still tasteful.
    private func aura(t: TimeInterval) -> some View {
        let hue = 0.40 + 0.05 * sin(t * (2 * .pi / 4.0)) // gentle drift around Gua green
        let drift = size * 0.06

        return shape
            .fill(Color(hue: hue, saturation: 0.8, brightness: 0.95))
            .opacity(0.30) // steady glow — no breathing
            .frame(width: size * 1.28, height: size * 1.28) // spill ~28% beyond the icon
            .offset(x: cos(t * (2 * .pi / 5.0)) * drift,
                    y: sin(t * (2 * .pi / 6.0)) * drift)
            .blur(radius: size * 0.28)
            .allowsHitTesting(false)
    }
}

/// Publishes the device's `roll` and `pitch` (each roughly -1...1) from `CoreMotion`, smoothed so the
/// parallax tilt eases rather than jitters. Device-motion updates require no `Info.plist` permission.
/// On hardware without a gyroscope (e.g. the simulator) `isDeviceMotionAvailable` is `false`, so the
/// values stay at zero and the logo simply doesn't tilt.
@Observable
final class DeviceTiltMotion {
    private(set) var roll: Double = 0
    private(set) var pitch: Double = 0

    @ObservationIgnored private let manager = CMMotionManager()

    func start() {
        guard manager.isDeviceMotionAvailable, !manager.isDeviceMotionActive else { return }

        manager.deviceMotionUpdateInterval = 1 / 30
        manager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let self, let attitude = motion?.attitude else { return }
            // Clamp to a small range and ease towards the target so motion is gentle and smooth.
            let targetRoll = max(-1, min(1, attitude.roll / (.pi / 6)))
            let targetPitch = max(-1, min(1, attitude.pitch / (.pi / 6)))
            roll += (targetRoll - roll) * 0.15
            pitch += (targetPitch - pitch) * 0.15
        }
    }

    func stop() {
        manager.stopDeviceMotionUpdates()
        roll = 0
        pitch = 0
    }
}
