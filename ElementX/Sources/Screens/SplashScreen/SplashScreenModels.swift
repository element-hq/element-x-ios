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

// MARK: - Coordinator

enum SplashScreenCoordinatorAction {
    case login
}

/// The content displayed in a single splash screen page.
struct SplashScreenPageContent {
    let title: AttributedString
    let message: String
    let image: ImageAsset
}

// MARK: View model

enum SplashScreenViewModelAction {
    case login
}

// MARK: View

struct SplashScreenViewState: BindableState {
    /// The colours of the background gradient shown behind the 4 pages.
    private let gradientColors = [
        Color(red: 0.95, green: 0.98, blue: 0.96),
        Color(red: 0.89, green: 0.96, blue: 0.97),
        Color(red: 0.95, green: 0.89, blue: 0.97),
        Color(red: 0.81, green: 0.95, blue: 0.91),
        Color(red: 0.95, green: 0.98, blue: 0.96)
    ]
    
    /// An array containing all content of the carousel pages
    let content: [SplashScreenPageContent]
    var bindings: SplashScreenBindings
    
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
            SplashScreenPageContent(title: ElementL10n.ftueAuthCarouselSecureTitle.tinting("."),
                                    message: ElementL10n.ftueAuthCarouselSecureBody,
                                    image: Asset.Images.splashScreenPage1),
            SplashScreenPageContent(title: ElementL10n.ftueAuthCarouselControlTitle.tinting("."),
                                    message: ElementL10n.ftueAuthCarouselControlBody,
                                    image: Asset.Images.splashScreenPage2),
            SplashScreenPageContent(title: ElementL10n.ftueAuthCarouselEncryptedTitle.tinting("."),
                                    message: ElementL10n.ftueAuthCarouselEncryptedBody,
                                    image: Asset.Images.splashScreenPage3),
            SplashScreenPageContent(title: page4Title.tinting("."),
                                    message: ElementL10n.ftueAuthCarouselWorkplaceBody(ElementInfoPlist.cfBundleName),
                                    image: Asset.Images.splashScreenPage4)
        ]
        bindings = SplashScreenBindings()
    }
}

struct SplashScreenBindings {
    var pageIndex = 0
}

enum SplashScreenViewAction {
    case login
}
