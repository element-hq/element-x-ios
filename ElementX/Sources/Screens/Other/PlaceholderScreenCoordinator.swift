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

class PlaceholderScreenCoordinator: CoordinatorProtocol {
    private let showsBackgroundGradient: Bool
    
    init(showsBackgroundGradient: Bool = false) {
        self.showsBackgroundGradient = showsBackgroundGradient
    }
    
    func toPresentable() -> AnyView {
        AnyView(PlaceholderScreen(showsBackgroundGradient: showsBackgroundGradient))
    }
}

/// The screen shown in split view when the detail has no content.
struct PlaceholderScreen: View {
    let showsBackgroundGradient: Bool
    
    var body: some View {
        OnboardingLogo(isOnGradient: showsBackgroundGradient)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background {
                if showsBackgroundGradient {
                    OnboardingScreenBackgroundImage()
                }
            }
            .background()
            .environment(\.backgroundStyle, AnyShapeStyle(Color.compound.bgCanvasDefault))
            .ignoresSafeArea(edges: .top)
    }
}

struct PlaceholderScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        PlaceholderScreen(showsBackgroundGradient: false)
            .previewDisplayName("Screen")
        
        PlaceholderScreen(showsBackgroundGradient: true)
            .previewDisplayName("With background")
        
        NavigationSplitView {
            List {
                ForEach("Nothing to see here".split(separator: " "), id: \.self) { word in
                    Text(word)
                }
            }
        } detail: {
            PlaceholderScreen(showsBackgroundGradient: false)
        }
        .previewDisplayName("Split View")
        .previewInterfaceOrientation(.landscapeLeft)
    }
}
