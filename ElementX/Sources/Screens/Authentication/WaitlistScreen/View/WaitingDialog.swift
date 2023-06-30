//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

/// A standardised layout for waiting dialogs shown during the onboarding flow.
struct WaitingDialog<Content: View, BottomContent: View>: View {
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    /// Not using the default to allow the gradient to fill edge to edge.
    private let horizontalPadding = 16.0
    /// The top padding of the content, used to keep the text below the image.
    private var contentTopPadding: CGFloat {
        if verticalSizeClass == .compact {
            // Reduced value for iPhones in landscape.
            return UIConstants.onboardingBreakerScreenTopPadding
        } else if horizontalSizeClass == .compact {
            // The default value for portrait iPhones.
            return 2 * UIConstants.onboardingBreakerScreenTopPadding
        } else {
            // Larger on iPad specifically for 11" in Landscape.
            return 2.7 * UIConstants.onboardingBreakerScreenTopPadding
        }
    }
    
    /// The main content shown at the top of the layout.
    @ViewBuilder var content: () -> Content
    /// The content shown at the bottom of the layout.
    @ViewBuilder var bottomContent: () -> BottomContent
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.onboardingBreakerScreenTopPadding, horizontalPadding: 0) {
            content()
                .padding(.top, contentTopPadding)
                .padding(.horizontal, horizontalPadding)
        } bottomContent: {
            bottomContent()
                .padding(.horizontal, horizontalPadding)
        }
        .background {
            background
                .ignoresSafeArea(edges: [.horizontal, .bottom])
        }
        .ignoresSafeArea(edges: [.horizontal, .bottom])
        .environment(\.backgroundStyle, AnyShapeStyle(Color.compound.bgCanvasDefault))
        .environment(\.colorScheme, .dark)
        .toolbar(.visible, for: .navigationBar) // Layout consistency in all states.
        .toolbarBackground(.hidden, for: .navigationBar)
        .preferredColorScheme(.light) // FIXME: Doesn't do the nav bar?
    }
    
    var background: some View {
        // Negative spacing to hide a rendering bug that shows the white background.
        GeometryReader { geometry in
            VStack(spacing: -5) {
                Color.white
                    .frame(maxHeight: UIConstants.onboardingBreakerScreenTopPadding)
                
                Image(asset: Asset.Images.waitingGradient)
                    .resizable()
                    .frame(width: horizontalSizeClass == .compact ? nil : geometry.size.width) // Forced for landscape iPhone and nicer iPad.
                    .scaledToFit()
                    .layoutPriority(1) // Force for all landscape layouts.
                
                Color.compound.bgCanvasDefault
            }
        }
    }
}

struct WaitingDialog_Previews: PreviewProvider {
    static let viewModel = WaitlistScreenViewModel(homeserver: .mockMatrixDotOrg)
    
    static var previews: some View {
        NavigationStack {
            WaitlistScreen(context: viewModel.context)
        }
    }
}
