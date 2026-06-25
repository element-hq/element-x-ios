//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The app's logo with an "Apple-Intelligence/Siri"-style living aura: a flowing, multi-hue
/// conic gradient continuously rotates behind the icon and spills out as a soft glow.
///
/// The motion is driven by **Core Animation** (a `CABasicAnimation` on the gradient layer),
/// not SwiftUI's animation timeline — so it runs reliably whenever the view is on screen.
/// It is disabled when the user prefers reduced motion.
struct AuthenticationStartLogo: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    /// Set to `true` when using on top of `Asset.Images.launchBackground`
    let isOnGradient: Bool

    /// Extra padding needed to avoid cropping the shadows.
    private let extra: CGFloat = 32
    /// The shape that the logo is composed on top of.
    private let outerShape = RoundedRectangle(cornerRadius: 44)
    private let outerShapeShadowColor = Color(red: 0.11, green: 0.11, blue: 0.13)
    private var isLight: Bool {
        colorScheme == .light
    }

    var body: some View {
        logo
            // The living aura, behind the icon and oversized so colour spills past the edges as a
            // glow. Pure SwiftUI (an AngularGradient that rotates + breathes) so it renders AND
            // animates reliably on device — a Core Animation layer in a SwiftUI background often
            // never starts. Always drawn; the motion is suppressed under Reduce Motion.
            .background {
                GeometryReader { proxy in
                    SiriAura(animated: !reduceMotion)
                        .frame(width: proxy.size.width, height: proxy.size.height)
                        .scaleEffect(2.0)
                        .allowsHitTesting(false)
                }
            }
    }

    private var logo: some View {
        Image(asset: Asset.Images.appLogo)
            .resizable()
            .scaledToFit()
            .scaleEffect(0.8)
            .clipShape(outerShape)
            .overlay(alignment: .center) {
                outerShape
                    .inset(by: 0.25)
                    .stroke(.white.opacity(isLight ? 1 : isOnGradient ? 0.9 : 0.25), lineWidth: 0.5)
                    .blendMode(isLight ? .normal : .overlay)
            }
            .padding(extra)
            .background {
                ZStack {
                    if !isLight, isOnGradient {
                        outerShape
                            .inset(by: 1)
                            .padding(extra)
                            .shadow(color: .black.opacity(0.5),
                                    radius: 32.91666,
                                    y: 1.05333)
                    } else {
                        outerShape
                            .inset(by: 1)
                            .padding(extra)
                            .shadow(color: outerShapeShadowColor.opacity(isLight ? 0.23 : 0.08),
                                    radius: 16,
                                    y: 8)

                        outerShape
                            .inset(by: 1)
                            .padding(extra)
                            .shadow(color: outerShapeShadowColor.opacity(0.5),
                                    radius: 16,
                                    y: 8)
                            .blendMode(.overlay)
                    }
                }
                .mask {
                    outerShape
                        .inset(by: -extra / 2)
                        .stroke(lineWidth: extra)
                        .padding(extra)
                }
            }
            .padding(-extra)
            .accessibilityHidden(true)
    }
}

/// A flowing, multi-hue "Apple-Intelligence/Siri"-style glow: an angular (conic) gradient that
/// rotates continuously and breathes, written in pure SwiftUI so it reliably renders AND animates
/// on device. (A Core Animation layer in a SwiftUI `.background` frequently never starts its
/// animation.) The glow is always drawn; `animated` only toggles the motion (for Reduce Motion).
private struct SiriAura: View {
    let animated: Bool

    @State private var angle: Double = 0
    @State private var breathing = false

    private let auraColors: [Color] = [
        Color(red: 0.20, green: 0.95, blue: 0.55), // Gua green
        Color(red: 0.10, green: 0.80, blue: 0.90), // cyan
        Color(red: 0.30, green: 0.55, blue: 1.00), // blue
        Color(red: 0.65, green: 0.40, blue: 1.00), // purple
        Color(red: 1.00, green: 0.45, blue: 0.70), // pink
        Color(red: 0.20, green: 0.95, blue: 0.55) // back to green
    ]

    var body: some View {
        GeometryReader { geometry in
            let dimension = min(geometry.size.width, geometry.size.height)

            AngularGradient(gradient: Gradient(colors: auraColors), center: .center)
                // Rotate the whole gradient (more reliably animatable than the `angle:` param) and
                // blur it into a soft round halo so the colour clearly spills around the logo.
                .rotationEffect(.degrees(angle))
                .clipShape(Circle())
                .blur(radius: dimension * 0.11)
                .opacity(breathing ? 1.0 : 0.5)
        }
        .onAppear {
            guard animated else { return }
            withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                angle = 360
            }
            withAnimation(.easeInOut(duration: 2).repeatForever(autoreverses: true)) {
                breathing = true
            }
        }
    }
}
