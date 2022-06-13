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
    case register
    case login
}

/// The content displayed in a single splash screen page.
struct SplashScreenPageContent {
    let title: AttributedString
    let message: String
    let image: ImageAsset
    let gradient: Gradient
}

// MARK: View model

enum SplashScreenViewModelAction {
    case register
    case login
}

// MARK: View

struct SplashScreenViewState: BindableState, CustomDebugStringConvertible {
    private enum Constants {
        static let gradientColors = [
            Color(red: 0.95, green: 0.98, blue: 0.96),
            Color(red: 0.89, green: 0.96, blue: 0.97),
            Color(red: 0.95, green: 0.89, blue: 0.97),
            Color(red: 0.81, green: 0.95, blue: 0.91),
            Color(red: 0.95, green: 0.98, blue: 0.96)
        ]
    }
    
    /// An array containing all content of the carousel pages
    let content: [SplashScreenPageContent]
    var bindings: SplashScreenBindings
    
    /// Custom debug description to reduce noise in the logs.
    var debugDescription: String {
        "SplashScreenViewState at page \(bindings.pageIndex)."
    }
    
    init() {
        // The pun doesn't translate, so we only use it for English.
        let locale = Locale.current
        let page4Title = locale.identifier.hasPrefix("en") ? "Cut the slack from teams." : ElementL10n.ftueAuthCarouselWorkplaceTitle
        
        self.content = [
            SplashScreenPageContent(title: ElementL10n.ftueAuthCarouselSecureTitle.tinting("."),
                                              message: ElementL10n.ftueAuthCarouselSecureBody,
                                              image: Asset.Images.splashScreenPage1,
                                              gradient: Gradient(colors: [Constants.gradientColors[0], Constants.gradientColors[1]])),
            SplashScreenPageContent(title: ElementL10n.ftueAuthCarouselControlTitle.tinting("."),
                                              message: ElementL10n.ftueAuthCarouselControlBody,
                                              image: Asset.Images.splashScreenPage2,
                                              gradient: Gradient(colors: [Constants.gradientColors[1], Constants.gradientColors[2]])),
            SplashScreenPageContent(title: ElementL10n.ftueAuthCarouselEncryptedTitle.tinting("."),
                                              message: ElementL10n.ftueAuthCarouselEncryptedBody,
                                              image: Asset.Images.splashScreenPage3,
                                              gradient: Gradient(colors: [Constants.gradientColors[2], Constants.gradientColors[3]])),
            SplashScreenPageContent(title: page4Title.tinting("."),
                                              message: ElementL10n.ftueAuthCarouselWorkplaceBody(ElementInfoPlist.cfBundleName),
                                              image: Asset.Images.splashScreenPage4,
                                              gradient: Gradient(colors: [Constants.gradientColors[3], Constants.gradientColors[4]]))
        ]
        self.bindings = SplashScreenBindings()
    }
}

struct SplashScreenBindings {
    var pageIndex = 0
}

enum SplashScreenViewAction {
    case register
    case login
}
