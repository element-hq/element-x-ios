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

enum MockServerSelectionScreenState: CaseIterable {
    case matrix
    case emptyAddress
    case invalidAddress
    case nonModal
    
    /// Generate the view struct for the screen state.
    @MainActor var viewModel: ServerSelectionScreenViewModel {
        switch self {
        case .matrix:
            return ServerSelectionScreenViewModel(homeserverAddress: "https://matrix.org",
                                                  slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL,
                                                  isModallyPresented: true)
                                                  
        case .emptyAddress:
            return ServerSelectionScreenViewModel(homeserverAddress: "",
                                                  slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL,
                                                  isModallyPresented: true)
        case .invalidAddress:
            let viewModel = ServerSelectionScreenViewModel(homeserverAddress: "thisisbad",
                                                           slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL,
                                                           isModallyPresented: true)
            viewModel.displayError(.footerMessage(L10n.errorUnknown))
            return viewModel
        case .nonModal:
            return ServerSelectionScreenViewModel(homeserverAddress: "https://matrix.org",
                                                  slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL,
                                                  isModallyPresented: false)
        }
    }
}
