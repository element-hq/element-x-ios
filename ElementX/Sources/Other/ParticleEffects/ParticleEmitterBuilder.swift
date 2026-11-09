//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum ParticleEmitterBuilder {
    /// Flakes are split between a near and a far layer, the far ones being smaller,
    /// dimmer and slower, which gives the snow some depth as it falls.
    static func buildSnowCells() -> [CAEmitterCell] {
        [makeSnowCell(scale: 0.5, alpha: 0.35, velocity: 70, birthRate: 12),
         makeSnowCell(scale: 0.25, alpha: 0.2, velocity: 40, birthRate: 24)]
    }
    
    /// Brighter and faster than `buildSnowCells`, so that it reaches down the view before fading out.
    static func buildSnowfallCells() -> [CAEmitterCell] {
        [makeSnowfallCell(scale: 0.5, alpha: 0.6, velocity: 300, birthRate: 60),
         makeSnowfallCell(scale: 0.25, alpha: 0.4, velocity: 200, birthRate: 120)]
    }
    
    /// Thin streaks falling fast and almost straight down.
    static func buildRainfallCells() -> [CAEmitterCell] {
        let drop = makeRoundedRectangleImage(size: CGSize(width: 2, height: 16), cornerRadius: 1)
        
        return [makeRainCell(shape: drop, alpha: 0.5, velocity: 900),
                makeRainCell(shape: drop, alpha: 0.3, velocity: 700)]
    }
    
    /// A cell per colour, alternating between the shapes, each particle getting its own random depth.
    /// The confetti is fired up from a single point, like a cannon.
    static func buildConfettiCells() -> [CAEmitterCell] {
        let shapes = [makeRoundedRectangleImage(size: CGSize(width: 20, height: 13), cornerRadius: 2),
                      makeCircleImage(radius: 5)]
        
        return confettiColors.enumerated().map { index, color in
            makeConfettiCell(shape: shapes[index % shapes.count], color: color)
        }
    }
    
    /// Confetti made of hearts in the given colours, swaying instead of spinning.
    static func buildHeartCells(colors: [UIColor]) -> [CAEmitterCell] {
        let heart = makeSymbolImage(systemName: "heart.fill", pointSize: 16)
        
        return colors.map { color in
            let cell = makeConfettiCell(shape: heart, color: color)
            // The same amount of hearts however many colours they come in.
            cell.birthRate = 480 / Float(colors.count)
            cell.spin = 0
            cell.spinRange = 2
            return cell
        }
    }
    
    /// Twinkles bursting out in every direction, shrinking as they fade.
    static func buildSparkleCells() -> [CAEmitterCell] {
        let sparkle = makeSymbolImage(systemName: "sparkle", pointSize: 16)
        
        return [UIColor.systemYellow, .systemOrange].map { color in
            let cell = CAEmitterCell()
            cell.setContents(sparkle)
            
            cell.birthRate = 150
            cell.lifetime = 1.2
            
            cell.velocity = 250
            cell.velocityRange = 100
            cell.emissionRange = 2 * .pi
            
            cell.color = color.cgColor
            cell.alphaSpeed = -0.8
            
            cell.scale = 0.6
            cell.scaleRange = 0.3
            cell.scaleSpeed = -0.4
            
            cell.spin = 2
            cell.spinRange = 4
            
            return cell
        }
    }
    
    /// Soft flames that burn from yellow to red as they rise and taper off, with embers flying out of them and smoke drifting above.
    static func buildFireCells() -> [CAEmitterCell] {
        let flame = CAEmitterCell()
        flame.setContents(makeSoftCircleImage(radius: 16))
        
        flame.birthRate = 300
        flame.lifetime = 0.9
        flame.lifetimeRange = 0.3
        
        // Fired from a line emitter, which unlike a point one aims a zero longitude straight up.
        // A negative acceleration keeps them rising.
        flame.velocity = 100
        flame.velocityRange = 40
        flame.emissionRange = .pi / 10
        flame.yAcceleration = -200
        
        // Starts yellow, losing green (orange, then red) and fading as it rises.
        flame.color = UIColor(red: 1, green: 0.85, blue: 0.3, alpha: 0.7).cgColor
        flame.greenSpeed = -1
        flame.blueSpeed = -0.4
        flame.alphaSpeed = -0.8
        
        flame.scale = 1
        flame.scaleRange = 0.3
        flame.scaleSpeed = -0.8
        
        let ember = CAEmitterCell()
        ember.setContents(makeCircleImage(radius: 2))
        
        ember.birthRate = 20
        ember.lifetime = 1.6
        ember.lifetimeRange = 0.5
        
        ember.velocity = 180
        ember.velocityRange = 80
        ember.emissionRange = .pi / 4
        ember.yAcceleration = -60
        
        ember.color = UIColor.systemOrange.cgColor
        ember.alphaSpeed = -0.6
        
        let smoke = CAEmitterCell()
        smoke.setContents(makeSoftCircleImage(radius: 24))
        
        smoke.birthRate = 30
        smoke.lifetime = 2.5
        smoke.lifetimeRange = 0.5
        
        // Slower than the flames so that it lingers above them, spreading out as it grows.
        smoke.velocity = 70
        smoke.velocityRange = 20
        smoke.emissionRange = .pi / 6
        smoke.yAcceleration = -30
        
        smoke.color = UIColor.systemGray.withAlphaComponent(0.3).cgColor
        smoke.alphaSpeed = -0.12
        
        smoke.scale = 0.5
        smoke.scaleSpeed = 0.4
        smoke.spinRange = 1
        
        return [flame, ember, smoke]
    }
    
    /// Rings of sparks, a burst per emitter layer.
    static func buildFireworkCells() -> [CAEmitterCell] {
        let spark = makeCircleImage(radius: 3)
        
        return confettiColors.map { color in
            let cell = CAEmitterCell()
            cell.setContents(spark)
            
            // Emits everything at once, roughly a hundred sparks.
            cell.birthRate = 2000
            cell.duration = 0.05
            cell.lifetime = 1.8
            
            // A narrow velocity range keeps the sparks together as a ring.
            cell.velocity = 220
            cell.velocityRange = 40
            cell.emissionRange = 2 * .pi
            cell.yAcceleration = 120
            
            cell.color = color.cgColor
            cell.alphaSpeed = -0.55
            
            cell.scale = 0.8
            
            return cell
        }
    }
    
    // MARK: - Private
    
    private static let confettiColors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemBlue, .systemPink]
    
    private static func makeSnowCell(scale: CGFloat, alpha: CGFloat, velocity: CGFloat, birthRate: Float) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.setContents(makeCircleImage(radius: 6))
        
        cell.birthRate = birthRate
        cell.lifetime = 30
        
        cell.velocity = velocity
        cell.velocityRange = velocity / 2
        
        cell.yAcceleration = 5
        
        cell.color = UIColor.systemBlue.withAlphaComponent(alpha).cgColor
        cell.alphaRange = 0.2
        
        cell.scale = scale
        cell.scaleRange = scale / 2
        
        // A pi longitude points straight down, the spread gives every flake its own
        // sideways drift. An xAcceleration would instead keep pushing them all the same way.
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 8
        
        return cell
    }
    
    private static func makeSnowfallCell(scale: CGFloat, alpha: CGFloat, velocity: CGFloat, birthRate: Float) -> CAEmitterCell {
        let cell = makeSnowCell(scale: scale, alpha: alpha, velocity: velocity, birthRate: birthRate)
        // Gone within the time the effect stays on screen instead of disappearing all at once.
        cell.alphaSpeed = -Float(alpha) / 3
        return cell
    }
    
    private static func makeRainCell(shape: UIImage, alpha: CGFloat, velocity: CGFloat) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.setContents(shape)
        
        cell.birthRate = 80
        cell.lifetime = 2
        
        cell.velocity = velocity
        cell.velocityRange = velocity / 4
        cell.yAcceleration = 200
        
        cell.color = UIColor.systemBlue.withAlphaComponent(alpha).cgColor
        
        // Straight down, the streaks aren't rotated to follow their direction.
        cell.emissionLongitude = .pi
        cell.emissionRange = .pi / 64
        
        return cell
    }
    
    private static func makeConfettiCell(shape: UIImage, color: UIColor) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.setContents(shape)
        
        cell.birthRate = 240
        cell.lifetime = 4
        
        // Shot a few hundred points up (the apex is velocity² / 2 * yAcceleration), so that it stays around where it was fired from.
        cell.velocity = 800
        cell.velocityRange = 250
        
        cell.yAcceleration = 900
        
        cell.color = color.withAlphaComponent(0.75).cgColor
        cell.alphaRange = 0.25
        
        cell.scale = 0.375
        cell.scaleRange = 0.25
        
        cell.spin = 4
        cell.spinRange = 8
        
        // A rectangle emitter aims a zero longitude to the right (along the x axis), so the cannon turns it a quarter up.
        // The narrow cone keeps the burst together and gravity brings it back down.
        cell.emissionLongitude = -.pi / 2
        cell.emissionRange = .pi / 8
        
        return cell
    }
    
    private static func makeCircleImage(radius: CGFloat) -> UIImage {
        let size = CGSize(width: radius * 2, height: radius * 2)
        
        return UIGraphicsImageRenderer(size: size).image { context in
            UIColor.white.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }
    
    /// A white circle fading out towards its edge.
    private static func makeSoftCircleImage(radius: CGFloat) -> UIImage {
        let size = CGSize(width: radius * 2, height: radius * 2)
        let colors = [UIColor.white.cgColor, UIColor.white.withAlphaComponent(0).cgColor] as CFArray
        let gradient = CGGradient(colorsSpace: nil, colors: colors, locations: nil)
        
        return UIGraphicsImageRenderer(size: size).image { context in
            let center = CGPoint(x: radius, y: radius)
            gradient.map { context.cgContext.drawRadialGradient($0, startCenter: center, startRadius: 0, endCenter: center, endRadius: radius, options: []) }
        }
    }
    
    private static func makeSymbolImage(systemName: String, pointSize: CGFloat) -> UIImage {
        let symbol = UIImage(systemName: systemName, withConfiguration: UIImage.SymbolConfiguration(pointSize: pointSize)) ?? UIImage()
        
        // Redrawn so that the cell's colour tints a plain white image, symbols are templates otherwise.
        return UIGraphicsImageRenderer(size: symbol.size).image { _ in
            symbol.withTintColor(.white).draw(at: .zero)
        }
    }
    
    private static func makeRoundedRectangleImage(size: CGSize, cornerRadius: CGFloat) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            UIColor.white.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius).fill()
        }
    }
}

private extension CAEmitterCell {
    func setContents(_ image: UIImage) {
        contents = image.cgImage
        contentsScale = image.scale
    }
}
