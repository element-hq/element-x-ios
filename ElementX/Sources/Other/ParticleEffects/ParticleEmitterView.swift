//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A SwiftUI wrapper for `ParticleEmitterLayerView` that displays a Core Animation particle effect.
///
/// Usage:
/// ```swift
/// ParticleEmitterView(type: .snow)
/// ```
struct ParticleEmitterView: UIViewRepresentable {
    let type: ParticleEmitterType
    /// The point the particles are emitted from, in global coordinates.
    var origin: CGPoint?
    
    func makeUIView(context: Context) -> ParticleEmitterLayerView {
        let view = ParticleEmitterLayerView()
        view.addEmitter(type, origin: origin)
        return view
    }
    
    func updateUIView(_ uiView: ParticleEmitterLayerView, context: Context) {
        uiView.addEmitter(type, origin: origin)
    }
}

extension View {
    /// Renders a particle effect on top of the view, pass `nil` to remove it. The particles are
    /// emitted from the edge of the view unless an origin (in global coordinates) is provided.
    /// Changing the trigger restarts the effect, even when it is otherwise identical.
    ///
    /// Anything presented above the view covers the effect, which is what keeps out of process
    /// UI such as photo pickers interactive - the system ignores touches on content the app draws over.
    func particleEffect(_ type: ParticleEmitterType?, origin: CGPoint? = nil, trigger: some Hashable = 0) -> some View {
        overlay {
            if let type {
                ParticleEmitterView(type: type, origin: origin)
                    .id(trigger)
                    .ignoresSafeArea()
                    .allowsHitTesting(false)
            }
        }
    }
}
