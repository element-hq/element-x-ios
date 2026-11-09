//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum ParticleEmitterType: Equatable {
    case snow
    /// A short burst of snow, falling from the top of the view and fading out.
    case snowfall
    /// A short burst of rain, falling from the top of the view.
    case rainfall
    case confetti
    case hearts(colors: [UIColor])
    /// Flames rising from the origin.
    case fire
}

final class ParticleEmitterLayerView: UIView {
    private var emitterLayers: [CAEmitterLayer] = []
    private let emitterType: ParticleEmitterType
    /// The point the particles are emitted from, in window coordinates.
    private let emitterOrigin: CGPoint?
    private var isWaitingToEmit = true
    @CancellableTask private var burstTask: Task<Void, Never>?
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError()
    }
    
    /// Emits the given particles, optionally from a specific point in window coordinates.
    init(type: ParticleEmitterType, origin: CGPoint?) {
        emitterType = type
        emitterOrigin = origin
        
        super.init(frame: .zero)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Implicit animations would otherwise sweep the emitter across the screen while it emits.
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        defer { CATransaction.commit() }
        
        emitterLayers.forEach(position)
        
        // The emitter is positioned using the view's bounds and its window, so a confetti
        // burst started before either of them exists would be emitted off screen and be over
        // by the time they do.
        if isWaitingToEmit, window != nil, bounds.size != .zero {
            isWaitingToEmit = false
            emit()
        }
    }
    
    override func didMoveToWindow() {
        super.didMoveToWindow()
        
        // A layout pass that ran before the window existed couldn't emit, and nothing else would trigger another one.
        if isWaitingToEmit {
            setNeedsLayout()
        }
    }
    
    // MARK: - Private
    
    private func emit() {
        let cells = switch emitterType {
        case .snow: ParticleEmitterBuilder.buildSnowCells()
        case .snowfall: ParticleEmitterBuilder.buildSnowfallCells()
        case .rainfall: ParticleEmitterBuilder.buildRainfallCells()
        case .confetti: ParticleEmitterBuilder.buildConfettiCells()
        case .hearts(let colors): ParticleEmitterBuilder.buildHeartCells(colors: colors)
        case .fire: ParticleEmitterBuilder.buildFireCells()
        }
        
        // Start mid simulation so that the snow already covers the view instead of falling into it.
        let beginTime = CACurrentMediaTime() - (emitterType == .snow ? 20 : 0)
        
        // Spread across emitters of a couple of cells each, one with more of them randomly never starts emitting.
        for index in stride(from: 0, to: cells.count, by: 2) {
            let emitterLayer = CAEmitterLayer()
            position(emitterLayer)
            emitterLayer.emitterCells = Array(cells[index..<min(index + 2, cells.count)])
            emitterLayer.beginTime = beginTime
            layer.addSublayer(emitterLayer)
            emitterLayers.append(emitterLayer)
        }
        
        guard emitterType != .snow else { return }
        
        UINotificationFeedbackGenerator().notificationOccurred(.success)
        
        // A single burst of particles, they keep animating until their lifetime runs out.
        burstTask = Task {
            guard await (try? Task.sleep(for: .milliseconds([.snowfall, .rainfall, .fire].contains(emitterType) ? 1000 : 250))) != nil else { return }
            emitterLayers.forEach { $0.birthRate = 0 }
        }
    }
    
    private func position(_ emitterLayer: CAEmitterLayer) {
        emitterLayer.frame = bounds
        
        switch emitterType {
        case .snow, .snowfall, .rainfall:
            // Falls in from above the view.
            emitterLayer.emitterShape = .line
            emitterLayer.emitterSize = CGSize(width: bounds.width, height: 1)
            emitterLayer.emitterPosition = CGPoint(x: bounds.midX, y: -20)
        case .confetti, .hearts:
            emitterLayer.emitterShape = .point
            emitterLayer.emitterSize = .zero
            emitterLayer.emitterPosition = emitterOrigin.map { convert($0, from: nil) } ?? CGPoint(x: bounds.midX, y: bounds.midY)
        case .fire:
            // A short line gives the flames a base instead of a single point.
            emitterLayer.emitterShape = .line
            emitterLayer.emitterSize = CGSize(width: 60, height: 1)
            emitterLayer.emitterPosition = emitterOrigin.map { convert($0, from: nil) } ?? CGPoint(x: bounds.midX, y: bounds.midY)
            // Overlapping flames glow in the dark, additive blending would wash them out to white in light mode.
            emitterLayer.renderMode = traitCollection.userInterfaceStyle == .dark ? .additive : .unordered
        }
    }
}
