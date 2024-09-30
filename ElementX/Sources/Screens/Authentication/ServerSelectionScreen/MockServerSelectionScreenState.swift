//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
