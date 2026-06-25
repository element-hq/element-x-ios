//
// Copyright 2025 Gua. All rights reserved.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CoreMotion
import SwiftUI

/// The welcome-screen app logo: the Gua app-icon artwork presented as a raised "liquid glass" object.
///
/// It comes alive in three independent ways:
///  - **Entrance** (one-shot, on appear): the logo flies in rapidly from the side and spins into
///    place — a 3D rotation that settles with a gentle spring. This is pure SwiftUI state, so it
///    plays on every device **and on the simulator**. Skipped under Reduce Motion (the logo just
///    appears).
///  - **Device-motion parallax** (`CoreMotion`): once settled, the wolf and chat bubble — split into
///    their own raised layers (`appLogoWolf`, `appLogoBubble`) above the gradient tile — lift and
///    slide at staggered depths as you tilt the phone, with a glass highlight tracking the tilt.
///    There is **no idle motion**: a still phone shows the clean, raised base icon. The simulator has
///    no gyroscope, so the parallax stays at rest there (expected — the *entrance* still plays).
///  - **Light** (`SwiftUI.TimelineView(.animation)`, display-link backed; the `SwiftUI.` qualifier
///    avoids ElementX's own `TimelineView`): an occasional specular sheen that sweeps across the glass
///    (~1s every ~11s) and a steady Gua-green aura that spills past the icon edges.
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
            if isLive { tilt.start() }
            guard !entered else { return }
            if animated {
                withAnimation(.spring(response: 0.52, dampingFraction: 0.66).delay(0.1)) {
                    entered = true
                }
            } else {
                entered = true // Reduce Motion / tests: appear in place, no fly-in.
            }
        }
        .onDisappear { tilt.stop() }
    }

    private func treated(t: TimeInterval) -> some View {
        // No breathing/pulsing — the logo comes alive only through light (the sheen sweep + the
        // tilt-tracking glass highlight) and the device-motion parallax tilt.
        logo
            .overlay { bubbleLayer() }
            .overlay { wolfLayer() }
            .overlay { sheen(t: t) }
            .overlay { glassHighlight() }
            .clipShape(shape)
            .overlay { shape.stroke(.white.opacity(0.16), lineWidth: 0.5) } // crisp glass edge
            .background { aura(t: t) }
            // Subtle device-motion parallax: ±5° max, no movement when the phone is still.
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

    /// Smoothed tilt magnitude (0 when the phone is flat). The raised layers fade in with it so a
    /// still phone shows the clean base icon and the depth only appears as you move the phone.
    private var motionMag: Double {
        (tilt.roll * tilt.roll + tilt.pitch * tilt.pitch).squareRoot()
    }

    // The chat bubble and the wolf are split into their OWN layers (`app-logo-bubble`,
    // `app-logo-wolf`) and stacked above the gradient tile at STAGGERED depths: the wolf shifts and
    // casts a deeper shadow than the bubble, which shifts more than the fixed tile. As the phone
    // tilts they read as physically raised glass (the "elevated liquid glass" idea, using the real
    // logo content). Both fade in only with motion, so a still phone shows the clean base icon.

    /// Mid layer: the chat-bubble outline, lifted a little off the tile.
    private func bubbleLayer() -> some View {
        Image(asset: Asset.Images.appLogoBubble)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.22), radius: size * 0.025,
                    x: -tilt.roll * size * 0.02, y: -tilt.pitch * size * 0.02)
            .offset(x: tilt.roll * size * 0.03, y: tilt.pitch * size * 0.03)
            .opacity(0.95) // always-on raised relief — stays visible when the phone is still
            .allowsHitTesting(false)
    }

    /// Top layer: the wolf, raised highest — biggest parallax shift + deepest shadow.
    private func wolfLayer() -> some View {
        Image(asset: Asset.Images.appLogoWolf)
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .shadow(color: .black.opacity(0.3), radius: size * 0.04,
                    x: -tilt.roll * size * 0.04, y: -tilt.pitch * size * 0.04)
            .offset(x: tilt.roll * size * 0.06, y: tilt.pitch * size * 0.06)
            .opacity(1) // always-on raised relief — stays visible when the phone is still
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
