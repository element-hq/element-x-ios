//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UIKit

enum ParticleEmitterType {
    case snow
    case confetti
}

final class ParticleEmitterLayerView: UIView {
    private let emitterLayer = CAEmitterLayer()
    private var emitterType: ParticleEmitterType?
    /// The point the particles are emitted from, in window coordinates.
    private var emitterOrigin: CGPoint?
    private var isWaitingToEmit = false
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    init() {
        super.init(frame: .zero)
        
        layer.addSublayer(emitterLayer)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        emitterLayer.frame = bounds
        
        if let emitterOrigin {
            emitterLayer.emitterShape = .point
            emitterLayer.emitterSize = .zero
            emitterLayer.emitterPosition = convert(emitterOrigin, from: nil)
        } else {
            emitterLayer.emitterShape = .line
            emitterLayer.emitterSize = CGSize(width: bounds.width, height: 1)
            
            // Snow falls in from above the view, confetti is shot up from the bottom of it.
            emitterLayer.emitterPosition = switch emitterType {
            case .snow, .none: CGPoint(x: bounds.midX, y: -20)
            case .confetti: CGPoint(x: bounds.midX, y: bounds.height)
            }
        }
        
        // The emitter is positioned using the view's bounds and its window, so a confetti
        // burst started before either of them exists would be emitted off screen and be over
        // by the time they do.
        if isWaitingToEmit, window != nil, bounds.size != .zero {
            isWaitingToEmit = false
            emit()
        }
    }
    
    /// Emits the given particles, optionally from a specific point in window coordinates.
    func addEmitter(_ type: ParticleEmitterType, origin: CGPoint? = nil) {
        guard type != emitterType || origin != emitterOrigin else { return }
        
        emitterType = type
        emitterOrigin = origin
        isWaitingToEmit = true
        
        setNeedsLayout()
    }
    
    // MARK: - Private
    
    private func emit() {
        guard let emitterType else { return }
        
        emitterLayer.birthRate = 1
        
        switch emitterType {
        case .snow:
            emitterLayer.emitterCells = ParticleEmitterBuilder.buildSnowCells()
            
            // Start mid simulation so that the snow already covers the view instead of falling into it.
            emitterLayer.beginTime = CACurrentMediaTime() - 20
            
        case .confetti:
            emitterLayer.emitterCells = ParticleEmitterBuilder.buildConfettiCells(fromPoint: emitterOrigin != nil)
            emitterLayer.beginTime = CACurrentMediaTime()
            
            // A single burst of particles, they keep animating until their lifetime runs out.
            Task {
                try? await Task.sleep(for: .milliseconds(250))
                emitterLayer.birthRate = 0
            }
        }
    }
}
