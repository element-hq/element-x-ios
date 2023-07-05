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

import Foundation

enum WelcomeScreenScreenViewModelAction {
    case dismiss
}

struct WelcomeScreenScreenViewState: BindableState {
    let title = L10n.screenWelcomeTitle(InfoPlistReader.main.bundleDisplayName)
    let subtitle = L10n.screenWelcomeSubtitle
    let bullet1 = L10n.screenWelcomeBullet1
    let bullet2 = L10n.screenWelcomeBullet2
    let bullet3 = L10n.screenWelcomeBullet3
    let buttonTitle = L10n.screenWelcomeButton
}

enum WelcomeScreenScreenViewAction {
    case doneTapped
    case appeared
}
