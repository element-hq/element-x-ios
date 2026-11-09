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
        
        // A point emitter aims a zero longitude to the right (along the x axis), so the cannon turns it a quarter up.
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
