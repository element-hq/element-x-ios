//
// Copyright 2022 New Vector Ltd
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

// MARK: - Coordinator

enum OnboardingCoordinatorAction {
    case login
}

/// The content displayed in a single screen page.
struct OnboardingPageContent {
    let title: AttributedString
    let message: String
    let image: ImageAsset
}

// MARK: View model

enum OnboardingViewModelAction {
    case login
}

// MARK: View

struct OnboardingViewState: BindableState {
    /// The colours of the background gradient shown behind the 4 pages.
    private let gradientColors = [
        Color(red: 0.95, green: 0.98, blue: 0.96),
        Color(red: 0.89, green: 0.96, blue: 0.97),
        Color(red: 0.95, green: 0.89, blue: 0.97),
        Color(red: 0.81, green: 0.95, blue: 0.91),
        Color(red: 0.95, green: 0.98, blue: 0.96)
    ]
    
    /// An array containing all content of the carousel pages
    let content: [OnboardingPageContent]
    var bindings: OnboardingBindings
    
    /// The background gradient for all 4 pages and the hidden page at the start of the carousel.
    var backgroundGradient: Gradient {
        if Tests.isRunningUITests {
            return Gradient(colors: [.white])
        }
        // Include the extra stop for the hidden page at the start of the carousel.
        // (The last color is the right-hand stop, but we need the left-hand stop,
        // so take the last but one color from the array).
        let hiddenPageColor = gradientColors[gradientColors.count - 2]
        return Gradient(colors: [hiddenPageColor] + gradientColors)
    }
    
    init() {
        // The pun doesn't translate, so we only use it for English.
        let locale = Locale.current
        let page4Title = locale.identifier.hasPrefix("en") ? "Cut the slack from teams." : ElementL10n.ftueAuthCarouselWorkplaceTitle
        
        content = [
            OnboardingPageContent(title: ElementL10n.ftueAuthCarouselSecureTitle.tinting("."),
                                  message: ElementL10n.ftueAuthCarouselSecureBody,
                                  image: Asset.Images.onboardingScreenPage1),
            OnboardingPageContent(title: ElementL10n.ftueAuthCarouselControlTitle.tinting("."),
                                  message: ElementL10n.ftueAuthCarouselControlBody,
                                  image: Asset.Images.onboardingScreenPage2),
            OnboardingPageContent(title: ElementL10n.ftueAuthCarouselEncryptedTitle.tinting("."),
                                  message: ElementL10n.ftueAuthCarouselEncryptedBody,
                                  image: Asset.Images.onboardingScreenPage3),
            OnboardingPageContent(title: page4Title.tinting("."),
                                  message: ElementL10n.ftueAuthCarouselWorkplaceBody(InfoPlistReader.target.bundleDisplayName),
                                  image: Asset.Images.onboardingScreenPage4)
        ]
        bindings = OnboardingBindings()
    }
}

struct OnboardingBindings {
    var pageIndex = 0
}

enum OnboardingViewAction {
    case login
}
