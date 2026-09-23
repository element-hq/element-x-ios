//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A particle effect to render with `particleEffect(_:)`. Every new value is a new effect, even when otherwise identical.
struct ParticleEffect: Equatable {
    /// Snow falling from the top of the view.
    static let snow = ParticleEffect(type: .snow, origin: nil)
    
    let type: ParticleEmitterType
    /// The point confetti is fired up from, in global coordinates. The middle of the view when `nil`.
    let origin: CGPoint?
    let id = UUID()
    
    static func confetti(from origin: CGPoint?) -> ParticleEffect {
        ParticleEffect(type: .confetti, origin: origin)
    }
}

/// A SwiftUI wrapper for `ParticleEmitterLayerView` that displays a Core Animation particle effect.
private struct ParticleEmitterView: UIViewRepresentable {
    let effect: ParticleEffect
    
    func makeUIView(context: Context) -> ParticleEmitterLayerView {
        ParticleEmitterLayerView(type: effect.type, origin: effect.origin)
    }
    
    /// `particleEffect` recreates the view for every change of effect instead, through its identity.
    func updateUIView(_ uiView: ParticleEmitterLayerView, context: Context) { }
}

extension View {
    /// Renders a particle effect on top of the view, pass `nil` to remove it.
    ///
    /// Anything presented above the view covers the effect, which is what keeps out of process
    /// UI such as photo pickers interactive - the system ignores touches on content the app draws over.
    func particleEffect(_ effect: ParticleEffect?) -> some View {
        overlay {
            if let effect {
                ParticleEmitterView(effect: effect)
                    .id(effect.id)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}
