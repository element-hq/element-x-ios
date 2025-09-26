//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import Foundation
import SwiftUI
import SwiftUIIntrospect

extension View {
    @ViewBuilder
    func bloom() -> some View {
        if #available(iOS 26, *) {
            modifier(BloomModifier())
        } else {
            modifier(OldBloomModifier())
        }
    }
}

private struct BloomModifier: ViewModifier {
    @State private var height = CGFloat.zero
    
    func body(content: Content) -> some View {
        content
            .onGeometryChange(for: CGFloat.self) { proxy in
                proxy.safeAreaInsets.top
            } action: { height in
                self.height = height
            }
            .overlay(alignment: .top) {
                LinearGradient(gradient: .compound.subtle,
                               startPoint: .top,
                               endPoint: .init(x: 0.5, y: 0.35))
                    .ignoresSafeArea(edges: .all)
                    .frame(height: height)
                    .allowsHitTesting(false)
                    // Does not render properly on dark themes otherwise
                    .colorScheme(.light)
            }
    }
}

private struct OldBloomModifier: ViewModifier {
    @Environment(\.colorScheme) private var colorScheme
    
    @State private var standardAppearance = UINavigationBarAppearance()
    @State private var scrollEdgeAppearance = UINavigationBarAppearance()
    
    @State private var bloom = Bloom()
    
    func body(content: Content) -> some View {
        content
            .introspect(.viewController, on: .supportedVersions, customize: configureBloom)
    }
    
    private func configureBloom(controller: UIViewController) {
        if controller.navigationItem.standardAppearance == standardAppearance,
           controller.navigationItem.scrollEdgeAppearance == scrollEdgeAppearance,
           canUse(bloom) {
            return
        }
        
        let bloom = makeBloom()
        
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundImage = bloom.image
        standardAppearance.backgroundImageContentMode = .scaleToFill
        controller.navigationItem.standardAppearance = standardAppearance
        
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.backgroundImage = bloom.image
        scrollEdgeAppearance.backgroundImageContentMode = .scaleToFill
        scrollEdgeAppearance.backgroundColor = .compound.bgCanvasDefault
        controller.navigationItem.scrollEdgeAppearance = scrollEdgeAppearance
    }
    
    private func makeBloom() -> Bloom {
        if bloom.image != nil, canUse(bloom) {
            return bloom
        }
        
        // There's a bug somewhere when rendering in dark mode (which we've mistakenly not been doing)
        // which results in the first 5 stops not having any alpha, only the last one…
        let newImage = ImageRenderer(content: bloomGradient /* .colorScheme(colorScheme) */ ).uiImage
        
        bloom.image = newImage
        bloom.colorScheme = colorScheme
        bloom.baseColor = .compound.gradientSubtleStop1
        return bloom
    }
    
    private var bloomGradient: some View {
        LinearGradient(gradient: .compound.subtle,
                       startPoint: .top,
                       endPoint: .init(x: 0.5, y: 0.7))
            .ignoresSafeArea(edges: .all)
            .frame(width: 256, height: 256)
    }
    
    private func canUse(_ bloom: Bloom) -> Bool {
        // Don't check for a nil image in here, there's no point re-rendering over and over if the render fails.
        bloom.colorScheme == colorScheme && bloom.baseColor == .compound.gradientSubtleStop1
    }
    
    // This is a class to avoid a "Modifying state during view update" warning when storing
    // the result on the same run-loop - we want to avoid dispatching that to the next loop as
    // that can result in further (unnecessary) renders being made.
    class Bloom {
        var image: UIImage?
        var colorScheme: ColorScheme?
        var baseColor: Color?
    }
}
