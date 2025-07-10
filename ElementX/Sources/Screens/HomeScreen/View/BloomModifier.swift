//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import SwiftUIIntrospect

extension View {
    @ViewBuilder
    func bloom() -> some View {
        modifier(BloomModifier())
    }
}

private struct BloomModifier: ViewModifier {
    @State private var standardAppearance = UINavigationBarAppearance()
    @State private var scrollEdgeAppearance = UINavigationBarAppearance()
    
    @State private var bloomGradientImage: UIImage?
    
    func body(content: Content) -> some View {
        content
            .introspect(.viewController, on: .supportedVersions, customize: configureBloom)
    }
    
    private func configureBloom(controller: UIViewController) {
        guard controller.navigationItem.standardAppearance != standardAppearance,
              controller.navigationItem.scrollEdgeAppearance != scrollEdgeAppearance else {
            return
        }
        
        let image = makeBloomImage()
        
        standardAppearance.configureWithDefaultBackground()
        standardAppearance.backgroundImage = image
        standardAppearance.backgroundImageContentMode = .scaleToFill
        controller.navigationItem.standardAppearance = standardAppearance
        
        scrollEdgeAppearance.configureWithTransparentBackground()
        scrollEdgeAppearance.backgroundImage = image
        scrollEdgeAppearance.backgroundImageContentMode = .scaleToFill
        scrollEdgeAppearance.backgroundColor = .compound.bgCanvasDefault
        controller.navigationItem.scrollEdgeAppearance = scrollEdgeAppearance
    }
    
    private func makeBloomImage() -> UIImage? {
        if let bloomGradientImage {
            return bloomGradientImage
        }
        
        let newImage = ImageRenderer(content: bloomGradient).uiImage
        Task { bloomGradientImage = newImage }
        return newImage
    }
    
    private var bloomGradient: some View {
        LinearGradient(gradient: .compound.subtle,
                       startPoint: .top,
                       endPoint: .init(x: 0.5, y: 0.7))
            .ignoresSafeArea(edges: .all)
            .frame(width: 256, height: 256)
    }
}
