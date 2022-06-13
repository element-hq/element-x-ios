// 
// Copyright 2021 New Vector Ltd
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

struct SplashScreenPage: View {
    
    // MARK: - Properties
    
    // MARK: Private
    
    @Environment(\.colorScheme) private var colorScheme
    
    // MARK: Public
    
    /// The content that this page should display.
    let content: SplashScreenPageContent
    /// The height of the non-scrollable content in the splash screen.
    let overlayHeight: CGFloat
    
    // MARK: - Views
    
    @ViewBuilder
    var backgroundGradient: some View {
        if colorScheme != .dark {
            LinearGradient(gradient: content.gradient, startPoint: .leading, endPoint: .trailing)
                .flipsForRightToLeftLayoutDirection(true)
        }
    }
    
    var body: some View {
        VStack {
            VStack {
                Image(content.image.name)
                    .resizable()
                    .scaledToFit()
                    .frame(maxWidth: 300)
                    .padding(20)
                    .accessibilityHidden(true)
                
                VStack(spacing: 8) {
                    Text(content.title)
                        .font(.element.title2B)
                        .foregroundColor(.element.primaryContent)
                    Text(content.message)
                        .font(.element.body)
                        .foregroundColor(.element.secondaryContent)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom)
                
                Spacer()
                
                // Prevent the content from clashing with the overlay content.
                Spacer().frame(maxHeight: overlayHeight)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: OnboardingMetrics.maxContentWidth,
                   maxHeight: OnboardingMetrics.maxContentHeight)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(backgroundGradient.ignoresSafeArea())
    }
}

struct SplashScreenPage_Previews: PreviewProvider {
    static let content = SplashScreenViewState().content
    static var previews: some View {
        ForEach(0..<content.count, id: \.self) { index in
            SplashScreenPage(content: content[index], overlayHeight: 200)
        }
    }
}
