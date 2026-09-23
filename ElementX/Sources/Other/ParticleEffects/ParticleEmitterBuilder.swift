//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import UIKit

enum ParticleEmitterBuilder {
    /// Flakes are split between a near and a far layer, the far ones being smaller,
    /// dimmer and slower, which gives the snow some depth as it falls.
    static func buildSnowCells() -> [CAEmitterCell] {
        [snowCell(scale: 0.5, alpha: 0.35, velocity: 70, birthRate: 12),
         snowCell(scale: 0.25, alpha: 0.2, velocity: 40, birthRate: 24)]
    }
    
    /// A cell per colour, shape and depth, all of them tinting the same white shapes.
    ///
    /// - Parameter fromPoint: whether the confetti erupts in every direction from a single point
    ///   rather than being shot up from an edge of the view.
    static func buildConfettiCells(fromPoint: Bool) -> [CAEmitterCell] {
        let shapes = [roundedRectangleImage(size: CGSize(width: 20, height: 13), cornerRadius: 2, color: .white),
                      circleImage(radius: 5, color: .white)]
        
        return confettiColors.flatMap { color in
            shapes.flatMap { shape in
                [confettiCell(shape: shape, color: color, scale: 0.5, alpha: 1, fromPoint: fromPoint),
                 confettiCell(shape: shape, color: color, scale: 0.25, alpha: 0.5, fromPoint: fromPoint)]
            }
        }
    }
    
    // MARK: - Private
    
    private static let confettiColors: [UIColor] = [.systemRed, .systemOrange, .systemYellow, .systemGreen, .systemMint,
                                                    .systemTeal, .systemBlue, .systemIndigo, .systemPink]
    
    private static func snowCell(scale: CGFloat, alpha: CGFloat, velocity: CGFloat, birthRate: Float) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.setContents(circleImage(radius: 6, color: .white))
        
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
    
    private static func confettiCell(shape: UIImage, color: UIColor, scale: CGFloat, alpha: CGFloat, fromPoint: Bool) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.setContents(shape)
        
        cell.birthRate = 40
        cell.lifetime = fromPoint ? 4 : 6
        
        // Shot up fast enough to reach the top of a full screen (the apex is velocity² / 2 * yAcceleration)
        // or thrown outwards more gently when erupting from a point, so that it stays around it.
        cell.velocity = fromPoint ? 450 : 1200
        cell.velocityRange = fromPoint ? 250 : 300
        
        cell.yAcceleration = fromPoint ? 900 : 700
        
        cell.color = color.withAlphaComponent(alpha).cgColor
        
        cell.scale = scale
        cell.scaleRange = scale / 2
        
        cell.spin = 4
        cell.spinRange = 8
        
        // A zero longitude shoots the confetti straight up, gravity brings it back down. A full
        // range ignores the longitude altogether, spraying the confetti all around the origin.
        cell.emissionLongitude = 0
        cell.emissionRange = fromPoint ? 2 * .pi : .pi / 6
        
        return cell
    }
    
    private static func circleImage(radius: CGFloat, color: UIColor) -> UIImage {
        let size = CGSize(width: radius * 2, height: radius * 2)
        
        return UIGraphicsImageRenderer(size: size).image { context in
            color.setFill()
            context.cgContext.fillEllipse(in: CGRect(origin: .zero, size: size))
        }
    }
    
    private static func roundedRectangleImage(size: CGSize, cornerRadius: CGFloat, color: UIColor) -> UIImage {
        UIGraphicsImageRenderer(size: size).image { _ in
            color.setFill()
            UIBezierPath(roundedRect: CGRect(origin: .zero, size: size), cornerRadius: cornerRadius).fill()
        }
    }
}

private extension CAEmitterCell {
    func setContents(_ image: UIImage) {
        guard let cgImage = image.cgImage else {
            MXLog.failure("Failed creating particle contents")
            return
        }
        
        contents = cgImage
        contentsScale = image.scale
    }
}
