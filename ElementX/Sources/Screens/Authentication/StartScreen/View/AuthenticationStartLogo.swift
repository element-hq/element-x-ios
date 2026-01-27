//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The app's logo styled to fit on various launch pages.
struct AuthenticationStartLogo: View {
    @Environment(\.colorScheme) private var colorScheme
    
    /// Set to `true` when using on top of `Asset.Images.launchBackground`
    let hideBrandChrome: Bool
    
    /// Extra padding needed to avoid cropping the shadows.
    private let extra: CGFloat = 64
    /// The shape that the logo is composed on top of.
    private let outerShape = RoundedRectangle(cornerRadius: 44)
    private let outerShapeShadowColor = Color(red: 0.11, green: 0.11, blue: 0.13)
    private var isLight: Bool {
        colorScheme == .light
    }
    
    var body: some View {
        if hideBrandChrome {
            Image(asset: Asset.Images.appLogo)
        } else {
            brandLogo
        }
    }
    
    private var brandLogo: some View {
        Image(asset: Asset.Images.appLogo)
            .background {
                Circle()
                    .inset(by: 1)
                    .shadow(color: .black.opacity(!isLight ? 0.3 : 0.4),
                            radius: 12.57143,
                            y: 6.28571)
                
                Circle()
                    .inset(by: 1)
                    .shadow(color: .black.opacity(0.5),
                            radius: 12.57143,
                            y: 6.28571)
                    .blendMode(.overlay)
            }
            .padding(24)
            .background {
                Color.white
                    .opacity(isLight ? 0.23 : 0.05)
            }
            .clipShape(outerShape)
            .overlay {
                outerShape
                    .inset(by: 0.25)
                    .stroke(.white.opacity(isLight ? 1 : 0.9), lineWidth: 0.5)
                    .blendMode(isLight ? .normal : .overlay)
            }
            .padding(extra)
            .background {
                ZStack {
                    if !isLight {
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
