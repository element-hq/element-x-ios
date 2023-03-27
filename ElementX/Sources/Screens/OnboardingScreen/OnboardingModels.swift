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

enum OnboardingViewModelAction {
    case login
}

struct OnboardingViewState: BindableState {
    /// An array containing all content of the carousel pages
    let content: [OnboardingPageContent]
    var bindings: OnboardingBindings
    
    init() {
        content = [
            OnboardingPageContent(title: L10n.screenOnboardingWelcomeTitle.tinting(".", color: .element.accent),
                                  message: L10n.screenOnboardingWelcomeSubtitle(InfoPlistReader.main.bundleDisplayName),
                                  image: Asset.Images.onboardingAppLogo)
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
