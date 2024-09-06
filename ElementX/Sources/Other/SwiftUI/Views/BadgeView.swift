//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct BadgeView: View {
    let size: Double
    
    var body: some View {
        Circle()
            .fill(.compound.iconCriticalPrimary)
            .frame(width: size, height: size)
    }
}

struct BadgeViewModifier: ViewModifier {
    let size: Double
    
    func body(content: Content) -> some View {
        content.mask {
            Rectangle()
                .fill(.white)
                .overlay(alignment: .topTrailing) {
                    Circle()
                        .fill(.black)
                        .frame(width: maskSize, height: maskSize)
                        .offset(maskOffset)
                }
                .compositingGroup()
                .luminanceToAlpha()
        }
        .overlay(alignment: .topTrailing) {
            BadgeView(size: size)
        }
    }
    
    private var maskSize: Double {
        size * 1.25
    }
    
    private var maskOffset: CGSize {
        .init(width: (maskSize - size) / 2, height: -(maskSize - size) / 2)
    }
}

extension View {
    @ViewBuilder
    func overlayBadge(_ size: Double, isBadged: Bool = true) -> some View {
        if isBadged {
            modifier(BadgeViewModifier(size: size))
        } else {
            self
        }
    }
}

struct BadgeView_Previews: PreviewProvider {
    static let circleGradient = LinearGradient(colors: [.green, .orange],
                                               startPoint: .topLeading,
                                               endPoint: .bottomTrailing)
    static let screenGradient = LinearGradient(colors: [.pink, .blue],
                                               startPoint: .top,
                                               endPoint: .bottom)
    static var previews: some View {
        Circle()
            .fill(circleGradient)
            .saturation(2.0)
            .frame(width: 100, height: 100)
            .overlayBadge(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background { screenGradient.opacity(0.3).ignoresSafeArea() }
    }
}
