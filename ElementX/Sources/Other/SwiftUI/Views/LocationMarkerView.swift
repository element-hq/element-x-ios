//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LocationMarkerView: View {
    var userProfile: UserProfileProxy?
    var fillColor = Color.compound.bgCanvasDefault
    var strokeColor = Color.compound.iconSecondaryAlpha
    var dotColor = Color.compound.iconPrimary
    @ScaledMetric var size: CGFloat = 42
    var mediaProvider: MediaProviderProtocol?
    
    private let circleCenter = CGPoint(x: 21, y: 21) // in SVG space
    private let circleRadius: CGFloat = 6 // in SVG space
    
    var body: some View {
        // Generated from the SVG
        Canvas { context, canvasSize in
            let scaleX = canvasSize.width / 42
            let scaleY = canvasSize.height / 50
            
            let pinPath = Path { p in
                p.move(to: CGPoint(x: 21 * scaleX, y: 49 * scaleY))
                p.addCurve(to: CGPoint(x: 17.6875 * scaleX, y: 47.7581 * scaleY),
                           control1: CGPoint(x: 19.25 * scaleX, y: 49 * scaleY),
                           control2: CGPoint(x: 18.1458 * scaleX, y: 48.4825 * scaleY))
                p.addCurve(to: CGPoint(x: 5.28125 * scaleX, y: 33.6313 * scaleY),
                           control1: CGPoint(x: 12.5833 * scaleX, y: 42.8525 * scaleY),
                           control2: CGPoint(x: 8.41667 * scaleX, y: 38.1332 * scaleY))
                p.addCurve(to: CGPoint(x: 1 * scaleX, y: 21.3674 * scaleY),
                           control1: CGPoint(x: 2.82292 * scaleX, y: 29.2846 * scaleY),
                           control2: CGPoint(x: 1 * scaleX, y: 25.1863 * scaleY))
                p.addCurve(to: CGPoint(x: 21 * scaleX, y: 1 * scaleY),
                           control1: CGPoint(x: 1 * scaleX, y: 10.2109 * scaleY),
                           control2: CGPoint(x: 9.5 * scaleX, y: 1 * scaleY))
                p.addCurve(to: CGPoint(x: 41 * scaleX, y: 21.3674 * scaleY),
                           control1: CGPoint(x: 32.5 * scaleX, y: 1 * scaleY),
                           control2: CGPoint(x: 41 * scaleX, y: 10.2109 * scaleY))
                p.addCurve(to: CGPoint(x: 36.7188 * scaleX, y: 33.6313 * scaleY),
                           control1: CGPoint(x: 41 * scaleX, y: 25.1863 * scaleY),
                           control2: CGPoint(x: 39.1771 * scaleX, y: 29.2846 * scaleY))
                p.addCurve(to: CGPoint(x: 24.3125 * scaleX, y: 47.7581 * scaleY),
                           control1: CGPoint(x: 33.5833 * scaleX, y: 38.1332 * scaleY),
                           control2: CGPoint(x: 29.4167 * scaleX, y: 42.8525 * scaleY))
                p.addCurve(to: CGPoint(x: 21 * scaleX, y: 49 * scaleY),
                           control1: CGPoint(x: 23.3333 * scaleX, y: 48.4825 * scaleY),
                           control2: CGPoint(x: 21.5833 * scaleX, y: 49 * scaleY))
                p.closeSubpath()
            }
            
            context.stroke(pinPath, with: .color(strokeColor), lineWidth: 2 * scaleX)
            context.fill(pinPath, with: .color(fillColor))
            
            // Dot
            let dotPath = Path(ellipseIn: CGRect(x: (circleCenter.x - circleRadius) * scaleX,
                                                 y: (circleCenter.y - circleRadius) * scaleY,
                                                 width: circleRadius * 2 * scaleX,
                                                 height: circleRadius * 2 * scaleY))
            context.fill(dotPath, with: .color(dotColor))
            
            // Draw resolved symbol centered on the circle
            if userProfile != nil, let symbol = context.resolveSymbol(id: 0) {
                let center = CGPoint(x: circleCenter.x * scaleX,
                                     y: circleCenter.y * scaleY)
                context.draw(symbol, at: center, anchor: .center)
            }
        } symbols: {
            if let userProfile {
                LoadableAvatarImage(url: userProfile.avatarURL,
                                    name: userProfile.displayName,
                                    contentID: userProfile.userID,
                                    avatarSize: .user(on: .map),
                                    mediaProvider: mediaProvider)
                    .overlay {
                        Circle().inset(by: 0.5).stroke(strokeColor)
                    }
                    .tag(0)
            }
        }
        .frame(width: size, height: size * 50 / 42)
        .alignmentGuide(VerticalAlignment.center) { dimensions in
            dimensions[.bottom]
        }
    }
}

struct LocationMarkerView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 30) {
            LocationMarkerView()
            
            LocationMarkerView()
                .colorScheme(.dark)
            
            LocationMarkerView(userProfile: UserProfileProxy.mockDan,
                               mediaProvider: MediaProviderMock(configuration: .init()))
            
            LocationMarkerView(userProfile: UserProfileProxy.mockDan,
                               mediaProvider: MediaProviderMock(configuration: .init()))
                .colorScheme(.dark)
        }
        .padding(16)
        .background(Color(red: 0.9, green: 0.85, blue: 0.8))
        .previewLayout(.sizeThatFits)
    }
}
