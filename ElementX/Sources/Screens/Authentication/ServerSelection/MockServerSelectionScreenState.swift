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

enum MockServerSelectionScreenState: CaseIterable {
    case matrix
    case emptyAddress
    case invalidAddress
    case nonModal
    
    /// Generate the view struct for the screen state.
    @MainActor var viewModel: ServerSelectionViewModel {
        switch self {
        case .matrix:
            return ServerSelectionViewModel(homeserverAddress: "https://matrix.org",
                                            hasModalPresentation: true)
        case .emptyAddress:
            return ServerSelectionViewModel(homeserverAddress: "",
                                            hasModalPresentation: true)
        case .invalidAddress:
            let viewModel = ServerSelectionViewModel(homeserverAddress: "thisisbad",
                                                     hasModalPresentation: true)
            viewModel.displayError(.footerMessage(ElementL10n.unknownError))
            return viewModel
        case .nonModal:
            return ServerSelectionViewModel(homeserverAddress: "https://matrix.org",
                                            hasModalPresentation: false)
        }
    }
}
